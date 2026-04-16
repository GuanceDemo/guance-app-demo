package com.ft.mobile.sdk.demo.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.ft.mobile.sdk.demo.R
import com.ft.mobile.sdk.demo.data.ProductItem
import com.squareup.picasso.Picasso

class ProductAdapter(
    private val dataList: List<ProductItem>,
    private val itemClick: OnItemClickListener
) : RecyclerView.Adapter<ProductAdapter.ProductViewHolder>() {

    interface OnItemClickListener {
        fun onItemClick(item: ProductItem)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ProductViewHolder {
        val itemView = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_product_list, parent, false)
        return ProductViewHolder(itemView)
    }

    override fun onBindViewHolder(holder: ProductViewHolder, position: Int) {
        holder.bind(dataList[position])
    }

    override fun getItemCount(): Int = dataList.size

    inner class ProductViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val productImage: ImageView = itemView.findViewById(R.id.product_item_image)
        private val productTag: TextView = itemView.findViewById(R.id.product_item_tag)
        private val productTitle: TextView = itemView.findViewById(R.id.product_item_title)
        private val productSubtitle: TextView = itemView.findViewById(R.id.product_item_subtitle)
        private val productPrice: TextView = itemView.findViewById(R.id.product_item_price)
        private val productRating: TextView = itemView.findViewById(R.id.product_item_rating)

        fun bind(item: ProductItem) {
            Picasso.get()
                .load(item.imageUrl)
                .placeholder(R.drawable.ic_android)
                .error(R.drawable.ic_android)
                .fit()
                .centerInside()
                .into(productImage)

            productTag.text = item.tag
            productTitle.text = item.title
            productSubtitle.text = item.subtitle
            productPrice.text = item.price
            productRating.text = item.rating
            itemView.setOnClickListener { itemClick.onItemClick(item) }
        }
    }
}
