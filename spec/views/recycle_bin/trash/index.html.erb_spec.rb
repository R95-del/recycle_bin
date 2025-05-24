require 'rails_helper'

RSpec.describe "recycle_bin/trash/index", type: :view do
  it "renders the empty state when no items" do
    assign(:deleted_items, [])
    assign(:model_types, [])

    render

    expect(rendered).to include("Your trash is empty!")
  end
end
