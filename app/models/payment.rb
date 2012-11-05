# == Schema Information
#
# Table name: payments
#
#  id              :integer          not null, primary key
#  apply_form_id   :integer
#  amount          :decimal(10, 2)   not null
#  received        :date             not null
#  description     :string(1024)
#  account         :string(255)
#  mean            :string(255)      not null
#  returned_date   :date
#  returned_amount :decimal(10, 2)
#  return_reason   :string(1024)
#  bank_code       :string(4)
#  spec_symbol     :string(255)
#  var_symbol      :string(255)
#  const_symbol    :string(255)
#  name            :string(255)
#

class Payment < ActiveRecord::Base
  create_date_time_accessors #"returned_date"
  enforce_schema_rules

  CSV_FIELDS = %w(amount received returned_amount returned_date return_reason)
  acts_as_convertible_to_csv :fields => CSV_FIELDS

  belongs_to :apply_form, :class_name => 'Outgoing::ApplyForm'

  validates_presence_of :returned_date, :if => Proc.new { |p| p.return_reason or p.returned_amount }
  validates_presence_of :return_reason, :if => Proc.new { |p| p.returned_date or p.returned_amount }
  validates_presence_of :returned_amount, :if => Proc.new { |p| p.returned_date or p.return_reason }

  validates_presence_of :account, :if => proc { |p| p.bank? }
  validates_inclusion_of :mean, :in => %w( CASH BANK )

  named_scope :returned, :conditions => [ 'returned_amount IS NOT NULL']
  named_scope :not_assigned, :conditions => [ 'apply_form_id IS NULL']

  def to_label
    # TODO
    "platba číslo #{id}"
  end

  def bank?
    mean == 'BANK'
  end

  def cash?
    mean == 'CASH'
  end

  def amount
    cash = read_attribute(:amount)
    return nil unless cash

    returned = self.returned_amount || 0
    cash - returned
  end

end

