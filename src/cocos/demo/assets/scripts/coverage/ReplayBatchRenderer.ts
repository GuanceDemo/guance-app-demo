import { _decorator, Mesh, Skeleton, SkinnedMeshBatchRenderer, SkinnedMeshRenderer, gfx, sys } from 'cc';

/** Creator 3.8.8 compatibility for the sample's interleaved two-joint meshes. */
@_decorator.ccclass('ReplayBatchRenderer')
export class ReplayBatchRenderer extends SkinnedMeshBatchRenderer {
  // The 3.8.8 Web compiler lowers the engine's super setters to this.skeleton
  // and this.mesh, recursively invoking those same setters. Reflect preserves
  // the receiver while invoking the original renderer implementation.
  get mesh(): Mesh | null { return Reflect.get(SkinnedMeshRenderer.prototype, 'mesh', this); }
  set mesh(value: Mesh | null) { Reflect.set(SkinnedMeshRenderer.prototype, 'mesh', value, this); }
  get skeleton(): Skeleton | null { return Reflect.get(SkinnedMeshRenderer.prototype, 'skeleton', this); }
  set skeleton(value: Skeleton | null) { Reflect.set(SkinnedMeshRenderer.prototype, 'skeleton', value, this); }

  constructor() {
    super();
    // Engine cookMeshes uses a private JSON clone which loses JSB struct
    // accessors. Replace only that conversion for this sample component.
    Object.defineProperty(this, '_createUnitMesh', { value: (index: number, mesh: Mesh) => this.createUnitMesh(index, mesh) });
  }

  private createUnitMesh(index: number, mesh: Mesh): Mesh {
    const source = mesh.struct;
    if (source.vertexBundles.length !== 1) throw new Error('Replay batch expects one interleaved vertex bundle');
    const bundle = source.vertexBundles[0]!;
    const uv = mesh.readAttribute(0, gfx.AttributeName.ATTR_TEX_COORD);
    if (!uv) throw new Error('Replay batch requires texture coordinates');
    const { count, stride } = bundle.view;
    const nextStride = stride + 12;
    const vertexLength = count * nextStride;
    let totalLength = vertexLength;
    const primitives = source.primitives.map(primitive => {
      const old = primitive.indexView;
      const indexView = old ? { offset: totalLength, length: old.length, count: old.count, stride: old.stride } : undefined;
      if (old) totalLength += old.length;
      return { primitiveMode: primitive.primitiveMode, vertexBundelIndices: Array.from(primitive.vertexBundelIndices), ...(indexView ? { indexView } : {}) };
    });
    const data = new Uint8Array(totalLength);
    const view = new DataView(data.buffer);
    for (let vertex = 0; vertex < count; vertex++) {
      const offset = bundle.view.offset + vertex * stride;
      const target = vertex * nextStride;
      data.set(mesh.data.subarray(offset, offset + stride), target);
      view.setFloat32(target + stride, index, sys.isLittleEndian);
      view.setFloat32(target + stride + 4, uv[vertex * 2]!, sys.isLittleEndian);
      view.setFloat32(target + stride + 8, uv[vertex * 2 + 1]!, sys.isLittleEndian);
    }
    source.primitives.forEach((primitive, i) => {
      const old = primitive.indexView;
      if (old) data.set(mesh.data.subarray(old.offset, old.offset + old.length), primitives[i]!.indexView!.offset);
    });
    const attributes = bundle.attributes.map(a => new gfx.Attribute(a.name, a.format, a.isNormalized, a.stream, a.isInstanced, a.location));
    attributes.push(new gfx.Attribute(gfx.AttributeName.ATTR_BATCH_ID, gfx.Format.R32F));
    attributes.push(new gfx.Attribute(gfx.AttributeName.ATTR_BATCH_UV, gfx.Format.RG32F));
    const result = new Mesh();
    result.reset({ struct: {
      vertexBundles: [{ attributes, view: { offset: 0, length: vertexLength, count, stride: nextStride } }],
      primitives,
      minPosition: source.minPosition,
      maxPosition: source.maxPosition,
    }, data });
    return result;
  }
}
