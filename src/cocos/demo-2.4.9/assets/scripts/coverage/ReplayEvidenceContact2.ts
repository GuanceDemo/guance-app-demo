const {ccclass}=cc._decorator;
@ccclass('ReplayEvidenceContact2')
export class ReplayEvidenceContact2 extends cc.Component {
 notify?:()=>void;
 onCollisionEnter():void{this.notify?.();}
 onBeginContact():void{this.notify?.();}
}
