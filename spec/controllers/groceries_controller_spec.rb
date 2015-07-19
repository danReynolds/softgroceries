require 'rails_helper'
require 'support/login_user'
require 'support/routes'

describe GroceriesController, type: :controller do
  include_context 'login user'

  let(:id) { grocery.id }
  let(:user_group_id) { user_group.id }
  it_should_behave_like 'routes', {
    new: { user_group_id: true },
    show: { id: true },
    edit: { id: true }
  }

  describe 'GET index' do
    subject { get :index, user_group_id: user_group, format: :json }

    it 'should have a data response' do
      subject
      resp = JSON.parse(response.body)
      expect(resp.has_key?('data')).to eq true
    end

    it 'should return all group groceries' do
      subject
      data = JSON.parse(response.body)['data']
      groceries = user_group.groceries

      expect(data.length).to eq groceries.length

      groceries.each_with_index do |g, i|
        expect(g.id).to eq data[i]['id']
        expect(g.name).to eq data[i]['name']
        expect(g.description).to eq data[i]['description']
        expect(g.items.count).to eq data[i]['count']
        expect(g.total.to_money.format).to eq data[i]['cost']
        expect(g.finished?).to eq data[i]['finished']
      end
    end
  end

  describe 'POST create' do
    let(:grocery_params) {
      {
        name: 'Test',
        description: 'Test'
      }
    }
    subject { post :create, grocery: grocery_params, user_group_id: user_group }

    context 'grocery is valid' do
      it 'should create a new grocery' do
        expect { subject }.to change(Grocery, :count).by 1
      end

      it 'should set the default group if nil' do
        expect(controller.current_user.default_group).to be_nil
        subject
        expect(controller.current_user.default_group).to eq user_group
      end
    end

    context 'grocery is invalid' do
      it 'should redirect to new template' do
        grocery_params[:name] = ""
        expect(subject).to render_template :new
      end
    end
  end

  describe 'PATCH finish' do
    let(:finish_params) {
      {
        name: 'Next list',
        description: 'Description',
        current_ids: user_group.groceries.first.items.first(1).map(&:id),
        next_ids: user_group.groceries.first.items.map(&:id)[1..-2]
      }
    }

    let(:grocery) { user_group.groceries.first }

    subject {
      patch :finish,
      id: user_group.groceries.first.id,
      finish: finish_params
    }

    context 'groceries are valid to finish' do
      it 'should finish the current grocery list' do
        expect(grocery.finished?).to eq false
        subject
        expect(grocery.reload.finished?).to eq true
      end

      it 'should remove specified items from current list' do
        current_items = grocery.items.first(1)
        subject
        expect(grocery.reload.items.to_a).to eq current_items
      end

      it 'should add specified items to the next list' do
        next_items = grocery.items[1..-2]
        subject
        new_grocery = user_group.groceries.last
        expect(new_grocery.reload.items.to_a).to eq next_items
      end

      it 'should redirect to the newly created grocery' do
        subject
        new_grocery = user_group.groceries.last
        expect(response).to redirect_to new_grocery
      end
    end

    context 'groceries are not both valid' do
      before :each do
        finish_params[:name] = ''
      end

      it 'should not finish the current grocery' do
        subject
        expect(grocery.reload.finished_at).to be_nil
      end

      it 'should not create the new grocery' do
        expect { subject }.to_not change(Grocery, :count)
      end

      it 'should notify that there was a problem' do
        expect(subject).to redirect_to grocery
      end
    end
  end

  describe 'POST email_group' do
    subject { post :email_group, id: grocery.id }

    it 'should deliver an email to each group member' do
      users = grocery.user_group.users
      expect { subject }.to change { ActionMailer::Base.deliveries.count }.by users.count
    end

    it 'should redirect to the grocery page' do
      expect(subject).to redirect_to grocery
    end
  end

  describe 'POST set_store' do
    let(:subject) { post :set_store, id: grocery.id, grocery_store: params }
    let(:params) { attributes_for(:grocery_store) }

    context 'when valid params' do
      it 'should finish successfully' do
        expect(subject).to be_ok
      end

      context 'with an existing store' do
        let(:store) { create(:grocery_store) }
        before(:each) { params[:place_id] = store.place_id }

        it 'should assign the store to the grocery list' do
          subject
          expect(grocery.reload.grocery_store).to eq store
        end

        it 'should not create a new store' do
          expect { subject }.to_not change(GroceryStore, :count)
        end
      end

      context 'with a new store' do
        it 'should create the new store' do
          expect { subject }.to change(GroceryStore, :count).by(1)
        end

        it 'should assign the new store to the grocery list' do
          subject
          grocery_store = GroceryStore.find_by_place_id(params[:place_id])
          expect(grocery.reload.grocery_store).to eq grocery_store
        end
      end
    end

    context 'when invalid params' do
      it 'should render an error' do
        params[:place_id] = nil
        expect(subject).to have_http_status(:internal_server_error)
      end
    end
  end

  describe 'GET recipes' do
    it 'should be successful' do
      stub_request(:get, /food2fork.com/).
        with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }).
        to_return(status: 200, body: '{}', headers: {})

      get :recipes, id: grocery.id, format: :json
      expect(response).to be_ok
    end
  end
end
