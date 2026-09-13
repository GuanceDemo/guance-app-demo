export class ProductItem {
  id: string = '';
  title: string = '';
  subtitle: string = '';
  imageUrl: string = '';
  price: string = '';
  rating: string = '';
  tag: string = '';

  constructor(
    id?: string,
    title?: string,
    subtitle?: string,
    imageUrl?: string,
    price?: string,
    rating?: string,
    tag?: string
  ) {
    this.id = id ?? '';
    this.title = title ?? '';
    this.subtitle = subtitle ?? '';
    this.imageUrl = imageUrl ?? '';
    this.price = price ?? '';
    this.rating = rating ?? '';
    this.tag = tag ?? '';
  }
}

export class ProductSpec {
  key: string = '';
  value: string = '';

  constructor(key?: string, value?: string) {
    this.key = key ?? '';
    this.value = value ?? '';
  }
}

export class ProductDetail extends ProductItem {
  stock: string = '';
  description: string = '';
  highlights: string[] = [];
  specs: ProductSpec[] = [];

  constructor(item?: ProductItem) {
    super(item?.id, item?.title, item?.subtitle, item?.imageUrl, item?.price, item?.rating, item?.tag);
  }
}
