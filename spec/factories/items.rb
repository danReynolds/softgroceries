FactoryGirl.define do
  factory :item do
    price_cents 0
    sequence(:name) { |n| "Item#{n}" }

    trait :with_grocery do
      ignore do
        grocery { create(:grocery) }
      end

      after(:create) do |instance, evaluator|
        instance.groceries << evaluator.grocery
      end
    end
  end
end
