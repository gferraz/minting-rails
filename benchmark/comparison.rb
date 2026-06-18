# frozen_string_literal: true

# Competitive benchmark: minting-rails vs money-rails
# Run with: bundle exec ruby benchmark/comparison.rb

ENV['RAILS_ENV'] = 'test'

require 'bundler/setup'
require_relative '../test/dummy/config/environment'
require 'money-rails'
MoneyRails::Hooks.init
require 'benchmark'

# ── Shared setup ────────────────────────────────────────────────

AMOUNT = BigDecimal('1234.56')
CURRENCY_CODE = 'USD'
NUM_RECORDS = 100
ITERATIONS = 1000

MINTING_MONEY = Mint.money(AMOUNT, CURRENCY_CODE)
MONEY_RAILS_MONEY = Money.from_amount(AMOUNT, CURRENCY_CODE)

# ── Create tables ───────────────────────────────────────────────

TABLES = %i[
  minting_single minting_composite
  minting_single_decimal minting_composite_decimal
  money_rails_single money_rails_composite
].freeze

begin
  ActiveRecord::Schema.define do
    create_table :minting_single, force: true do |t|
      t.integer :price
    end
    create_table :minting_composite, force: true do |t|
      t.integer :price_amount
      t.string  :price_currency
    end
    create_table :minting_single_decimal, force: true do |t|
      t.decimal :price
    end
    create_table :minting_composite_decimal, force: true do |t|
      t.decimal :price_amount
      t.string  :price_currency
    end
    create_table :money_rails_single, force: true do |t|
      t.integer :price_cents
      t.string  :price_currency
    end
    create_table :money_rails_composite, force: true do |t|
      t.integer :price_cents
      t.string  :price_currency
    end
  end

  # ── Models ───────────────────────────────────────────────────────

  MintingSingle = Class.new(ApplicationRecord) do
    self.table_name = 'minting_single'
    money_attribute :price, currency: CURRENCY_CODE
  end
  MintingComposite = Class.new(ApplicationRecord) do
    self.table_name = 'minting_composite'
    money_attribute :price
  end
  MintingSingleDecimal = Class.new(ApplicationRecord) do
    self.table_name = 'minting_single_decimal'
    money_attribute :price, currency: CURRENCY_CODE
  end
  MintingCompositeDecimal = Class.new(ApplicationRecord) do
    self.table_name = 'minting_composite_decimal'
    money_attribute :price
  end
  MoneyRailsSingle = Class.new(ApplicationRecord) do
    self.table_name = 'money_rails_single'
    monetize :price_cents, with_currency: ->(record) { record.price_currency }
  end
  MoneyRailsComposite = Class.new(ApplicationRecord) do
    self.table_name = 'money_rails_composite'
    monetize :price_cents, with_currency: :price_currency
  end

  # NOTE: money-rails is not benchmarked with decimal columns because it
  # natively stores amounts as cents (integer). It has no built-in support
  # for decimal amount columns.

  # ── Benchmarks ──────────────────────────────────────────────────

  puts '=' * 80
  puts 'Benchmark: minting-rails vs money-rails'
  puts "Ruby #{RUBY_VERSION}, Rails #{Rails.version}, SQLite3"
  puts "#{ITERATIONS} iterations per test, #{NUM_RECORDS} records for mass insert"
  puts 'NOTE: Both sides pass a Money object through the attribute setter (fair comparison)'
  puts '=' * 80
  puts

  Benchmark.bm(40) do |x|
    # ── 1. Instantiation ──────────────────────────────────────────
    puts '-' * 60
    puts 'Instantiation (passing Money object to setter)'
    puts '-' * 60
    x.report('minting-rails  (single integer):') do
      ITERATIONS.times { MintingSingle.new(price: MINTING_MONEY) }
    end
    x.report('minting-rails  (single decimal):') do
      ITERATIONS.times { MintingSingleDecimal.new(price: MINTING_MONEY) }
    end
    x.report('money-rails   (single integer):') do
      ITERATIONS.times { MoneyRailsSingle.new(price: MONEY_RAILS_MONEY) }
    end

    x.report('minting-rails  (comp integer):') do
      ITERATIONS.times { MintingComposite.new(price: MINTING_MONEY) }
    end
    x.report('minting-rails  (comp decimal):') do
      ITERATIONS.times { MintingCompositeDecimal.new(price: MINTING_MONEY) }
    end
    x.report('money-rails   (comp integer):') do
      ITERATIONS.times { MoneyRailsComposite.new(price: MONEY_RAILS_MONEY) }
    end

    # ── 2. Create + persist ───────────────────────────────────────
    puts '-' * 60
    puts 'Create + save individual (Money through setter)'
    puts '-' * 60
    x.report('minting-rails  (single integer):') do
      ITERATIONS.times { MintingSingle.create!(price: MINTING_MONEY) }
      MintingSingle.delete_all
    end
    x.report('minting-rails  (single decimal):') do
      ITERATIONS.times { MintingSingleDecimal.create!(price: MINTING_MONEY) }
      MintingSingleDecimal.delete_all
    end
    x.report('money-rails   (single integer):') do
      ITERATIONS.times { MoneyRailsSingle.create!(price: MONEY_RAILS_MONEY) }
      MoneyRailsSingle.delete_all
    end

    x.report('minting-rails  (comp integer):') do
      ITERATIONS.times { MintingComposite.create!(price: MINTING_MONEY) }
      MintingComposite.delete_all
    end
    x.report('minting-rails  (comp decimal):') do
      ITERATIONS.times { MintingCompositeDecimal.create!(price: MINTING_MONEY) }
      MintingCompositeDecimal.delete_all
    end
    x.report('money-rails   (comp integer):') do
      ITERATIONS.times { MoneyRailsComposite.create!(price: MONEY_RAILS_MONEY) }
      MoneyRailsComposite.delete_all
    end

    # ── 3. Read after reload ──────────────────────────────────────
    puts '-' * 60
    puts 'Read Money attribute from persisted record'
    puts '-' * 60
    ms  = MintingSingle.create!(price: MINTING_MONEY)
    msd = MintingSingleDecimal.create!(price: MINTING_MONEY)
    mr  = MoneyRailsSingle.create!(price: MONEY_RAILS_MONEY)
    mc  = MintingComposite.create!(price: MINTING_MONEY)
    mcd = MintingCompositeDecimal.create!(price: MINTING_MONEY)
    mrc = MoneyRailsComposite.create!(price: MONEY_RAILS_MONEY)

    x.report('minting-rails  (single integer):') do
      record = MintingSingle.find(ms.id)
      ITERATIONS.times { record.price }
    end
    x.report('minting-rails  (single decimal):') do
      record = MintingSingleDecimal.find(msd.id)
      ITERATIONS.times { record.price }
    end
    x.report('money-rails   (single integer):') do
      record = MoneyRailsSingle.find(mr.id)
      ITERATIONS.times { record.price }
    end

    x.report('minting-rails  (comp integer):') do
      record = MintingComposite.find(mc.id)
      ITERATIONS.times { record.price }
    end
    x.report('minting-rails  (comp decimal):') do
      record = MintingCompositeDecimal.find(mcd.id)
      ITERATIONS.times { record.price }
    end
    x.report('money-rails   (comp integer):') do
      record = MoneyRailsComposite.find(mrc.id)
      ITERATIONS.times { record.price }
    end

    # ── 4. Query ──────────────────────────────────────────────────
    puts '-' * 60
    puts 'Query (raw column values — both query the same way)'
    puts '-' * 60
    x.report('minting-rails  (single integer):') do
      ITERATIONS.times { MintingSingle.find_by(price: MINTING_MONEY) }
    end
    x.report('minting-rails  (single decimal):') do
      ITERATIONS.times { MintingSingleDecimal.find_by(price: MINTING_MONEY) }
    end
    x.report('money-rails   (single integer):') do
      ITERATIONS.times { MoneyRailsSingle.find_by(price_cents: MONEY_RAILS_MONEY) }
    end

    x.report('minting-rails  (comp integer):') do
      ITERATIONS.times { MintingComposite.find_by(price: MINTING_MONEY) }
    end
    x.report('minting-rails  (comp decimal):') do
      ITERATIONS.times { MintingCompositeDecimal.find_by(price: MINTING_MONEY) }
    end
    x.report('money-rails   (comp integer):') do
      ITERATIONS.times do
        MoneyRailsComposite.find_by(price_cents: MONEY_RAILS_MONEY,
                                    price_currency: MONEY_RAILS_MONEY.currency)
      end
    end

    # ── 5. Arithmetic ─────────────────────────────────────────────
    puts '-' * 60
    puts 'Arithmetic (add two money attributes)'
    puts '-' * 60
    ms1 = MintingSingle.create!(price: MINTING_MONEY)
    ms2 = MintingSingle.create!(price: MINTING_MONEY)
    mr1 = MoneyRailsSingle.create!(price: MONEY_RAILS_MONEY)
    mr2 = MoneyRailsSingle.create!(price: MONEY_RAILS_MONEY)

    x.report('minting-rails  (single integer):') do
      ITERATIONS.times { (ms1.price / 3) + (ms2.price * 2) }
    end
    x.report('money-rails   (single integer):') do
      ITERATIONS.times { (mr1.price / 3) + (mr2.price * 2) }
    end
  end

  # ── 6. Caching ──────────────────────────────────────────────────

  puts '-' * 60
  puts 'Repeated access ×1000 (caching demonstration)'
  puts '-' * 60
  puts 'Both cache the Money object, but composed_of used by Mint returns it with zero allocation.'
  puts 'Money-rails re-runs currency lookups and comparisons on every read.'
  puts

  mcc   = MintingComposite.create!(price: MINTING_MONEY)
  mcc_d = MintingCompositeDecimal.create!(price: MINTING_MONEY)
  mrcc  = MoneyRailsComposite.create!(price: MONEY_RAILS_MONEY)

  first = mcc.price
  second = mcc.price
  puts "minting-rails composite int same object? #{first.equal?(second)}"
  first_d = mcc_d.price
  second_d = mcc_d.price
  puts "minting-rails composite dec same object? #{first_d.equal?(second_d)}"
  first_mr = mrcc.price
  second_mr = mrcc.price
  puts "money-rails   composite int same object? #{first_mr.equal?(second_mr)}"
  puts

  Benchmark.bm(40) do |x|
    x.report('minting-rails  (comp integer):')  { ITERATIONS.times { mcc.price } }
    x.report('minting-rails  (comp decimal):')  { ITERATIONS.times { mcc_d.price } }
    x.report('money-rails   (comp integer):')   { ITERATIONS.times { mrcc.price } }
  end

  alloc_before = GC.stat(:total_allocated_objects)
  ITERATIONS.times { mcc.price }
  minting_int_alloc = GC.stat(:total_allocated_objects) - alloc_before

  alloc_before = GC.stat(:total_allocated_objects)
  ITERATIONS.times { mcc_d.price }
  minting_dec_alloc = GC.stat(:total_allocated_objects) - alloc_before

  alloc_before = GC.stat(:total_allocated_objects)
  ITERATIONS.times { mrcc.price }
  money_alloc = GC.stat(:total_allocated_objects) - alloc_before

  puts
  puts format('%-40s %10s', 'minting-rails (comp integer) allocated:', minting_int_alloc.to_s)
  puts format('%-40s %10s', 'minting-rails (comp decimal) allocated:', minting_dec_alloc.to_s)
  puts format('%-40s %10s', 'money-rails (comp integer) allocated:', money_alloc.to_s)
  puts

  # ── Mass insert ─────────────────────────────────────────────────

  puts
  puts '─' * 60
  puts "Mass insert (#{NUM_RECORDS} records in transaction, Money through setter)"
  puts '─' * 60

  mass_minting_single = Benchmark.measure do
    MintingSingle.transaction { NUM_RECORDS.times { MintingSingle.create!(price: MINTING_MONEY) } }
  end
  mass_minting_single_decimal = Benchmark.measure do
    MintingSingleDecimal.transaction do
      NUM_RECORDS.times do
        MintingSingleDecimal.create!(price: MINTING_MONEY)
      end
    end
  end
  mass_money_rails_single = Benchmark.measure do
    MoneyRailsSingle.transaction do
      NUM_RECORDS.times do
        MoneyRailsSingle.create!(price: MONEY_RAILS_MONEY)
      end
    end
  end
  mass_minting_composite = Benchmark.measure do
    MintingComposite.transaction do
      NUM_RECORDS.times do
        MintingComposite.create!(price: MINTING_MONEY)
      end
    end
  end
  mass_minting_composite_decimal = Benchmark.measure do
    MintingCompositeDecimal.transaction do
      NUM_RECORDS.times do
        MintingCompositeDecimal.create!(price: MINTING_MONEY)
      end
    end
  end
  mass_money_rails_composite = Benchmark.measure do
    MoneyRailsComposite.transaction do
      NUM_RECORDS.times do
        MoneyRailsComposite.create!(price: MONEY_RAILS_MONEY)
      end
    end
  end

  puts format('%-40s %10s', 'minting-rails (single integer):',
              "#{mass_minting_single.real.round(4)}s")
  puts format('%-40s %10s', 'minting-rails (single decimal):',
              "#{mass_minting_single_decimal.real.round(4)}s")
  puts format('%-40s %10s', 'money-rails  (single integer):',
              "#{mass_money_rails_single.real.round(4)}s")
  puts format('%-40s %10s', 'minting-rails (comp integer):',
              "#{mass_minting_composite.real.round(4)}s")
  puts format('%-40s %10s', 'minting-rails (comp decimal):',
              "#{mass_minting_composite_decimal.real.round(4)}s")
  puts format('%-40s %10s', 'money-rails  (comp integer):',
              "#{mass_money_rails_composite.real.round(4)}s")

# ── Cleanup ─────────────────────────────────────────────────────
rescue StandardError => e
  puts "\nError: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  raise
ensure
  ActiveRecord::Schema.define do
    TABLES.each { |t| drop_table t, force: true }
  end

  puts
  puts 'Done. Temporary tables dropped.'
end
