# frozen_string_literal: true

require 'spree/testing_support/factory_bot'
Spree::TestingSupport::FactoryBot.when_cherry_picked do
  Spree::TestingSupport::FactoryBot.deprecate_cherry_picking

  require 'spree/testing_support/factories/promotion_code_factory'
  require 'spree/testing_support/factories/variant_factory'
end

FactoryBot.define do
  factory :promotion, class: 'Spree::Promotion' do
    name { 'Promo' }

    transient do
      code { nil }
    end
    before(:create) do |promotion, evaluator|
      if evaluator.code
        promotion.codes << build(:promotion_code, promotion: promotion, value: evaluator.code)
      end
    end

    trait :with_action do
      after(:create) do |promotion, _evaluator|
        promotion.actions << Spree::Promotion::Actions::CreateAdjustment.new
      end
    end

    trait :with_adjustable_action do
      transient do
        preferred_amount { 10 }
        calculator_class { Spree::Calculator::FlatRate }
        promotion_action_class { Spree::Promotion::Actions::CreateItemAdjustments }
      end

      after(:create) do |promotion, evaluator|
        calculator = evaluator.calculator_class.new
        calculator.preferred_amount = evaluator.preferred_amount
        evaluator.promotion_action_class.create!(calculator: calculator, promotion: promotion)
      end
    end

    factory :promotion_with_action_adjustment, traits: [:with_adjustable_action]

    trait :with_line_item_adjustment do
      transient do
        adjustment_rate { 10 }
      end

      after(:create) do |promotion, evaluator|
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = evaluator.adjustment_rate
        Spree::Promotion::Actions::CreateItemAdjustments.create!(calculator: calculator, promotion: promotion)
      end
    end

    factory :promotion_with_item_adjustment, traits: [:with_line_item_adjustment]

    trait :with_free_shipping do
      after(:create) do |promotion|
        Spree::Promotion::Actions::FreeShipping.create!(promotion: promotion)
      end
    end

    trait :with_order_adjustment do
      transient do
        weighted_order_adjustment_amount { 10 }
      end

      after(:create) do |promotion, evaluator|
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = evaluator.weighted_order_adjustment_amount
        action = Spree::Promotion::Actions::CreateAdjustment.create!(calculator: calculator)
        promotion.actions << action
        promotion.save!
      end
    end
    factory :promotion_with_order_adjustment, traits: [:with_order_adjustment]

    trait :with_item_total_rule do
      transient do
        item_total_threshold_amount { 10 }
      end

      after(:create) do |promotion, evaluator|
        rule = Spree::Promotion::Rules::ItemTotal.create!(
          promotion: promotion,
          preferred_operator: 'gte',
          preferred_amount: evaluator.item_total_threshold_amount
        )
        promotion.rules << rule
        promotion.save!
      end
    end
    factory :promotion_with_item_total_rule, traits: [:with_item_total_rule]
    trait :with_first_order_rule do
      after(:create) do |promotion, _evaluator|
        rule = Spree::Promotion::Rules::FirstOrder.create!(
          promotion: promotion,
        )
        promotion.rules << rule
        promotion.save!
      end
    end
    factory :promotion_with_first_order_rule, traits: [:with_first_order_rule]
  end
end
