class ItemsController < ApplicationController
  extend HappyPath
  follow_happy_paths
  load_and_authorize_resource :grocery
  load_and_authorize_resource :item, through: :grocery, shallow: true

  def index
    render json: {
      data: items_data
    }
  end

  def update
    grocery_item = @item.grocery_item(@grocery)
    previous_item_values = format_item(grocery_item).slice(:price, :quantity, :units)
    previous_unit = grocery_item.to_unit
    updated_quantity = item_params[:groceries_items_attributes][:quantity].to_f

    if @item.update_attributes(item_params)
      next_unit = grocery_item.reload.to_unit

      # Convert quantity if compatible units and quantity unchanged
      if (updated_quantity == previous_item_values[:quantity] && previous_unit.compatible?(next_unit))
        grocery_item.update_attribute(
          :quantity,
          previous_unit.convert_to(next_unit.units).scalar.to_f
        )
      end

      render json: {
        data: {
          previous_item_values: previous_item_values,
          updated_item_values: format_item(grocery_item.reload).slice(:price, :quantity, :display_name, :units)
        }
      }
    else
      render nothing: true, status: :internal_server_error
    end
  end

  def auto_complete
    items = @grocery.user_group.privacy_items.select(:id, :description, :name)
      .with_name(params[:q]).order('LENGTH(items.name) ASC').limit(5)

    render json: {
      data: items.map do |item|
        {
          id: item.id,
          name: item.name,
          description: item.description
        }
      end
    }
  end

private
  def items_data
    @grocery.groceries_items.inject({ total: 0, items: [] }) do |acc, grocery_item|
      acc.tap do |a|
        a[:items] << format_item(grocery_item)
        a[:total] += grocery_item.price_or_estimated.to_f
      end
    end
  end

  def format_item(grocery_item)
    quantity = grocery_item.quantity
    {
      id: grocery_item.item.id,
      name: grocery_item.item.name,
      description: grocery_item.item.description.to_s,
      grocery_item_id: grocery_item.id,
      quantity: quantity == quantity.floor ? quantity.to_i : quantity.to_f,
      units: grocery_item.units,
      display_name: grocery_item.display_name,
      price: grocery_item.price_or_estimated.format(symbol: false).to_f,
      url: item_path(grocery_item.item.id),
      requester: grocery_item.requester_id
    }
  end

  def item_params
    params.require(:item).permit(
      :name,
      :description,
      groceries_items_attributes: [
        :price,
        :price_cents,
        :id,
        :quantity,
        :grocery_id,
        :units
      ]
    )
  end
end
