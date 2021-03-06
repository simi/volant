# == Schema Information
#
# Table name: infosheets
#
#  id                    :integer          not null, primary key
#  workcamp_id           :integer
#  document_file_name    :string(255)
#  document_content_type :string(255)
#  document_file_size    :integer
#  document_updated_at   :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  notes                 :text
#

class Infosheet < ActiveRecord::Base
  belongs_to :workcamp, :class_name => 'Workcamp'
  has_attached_file :document, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :whiny => false
  validates_attachment_presence :document

  def self.create_from_params(params)
    Infosheet.find(params['infosheet_id'])
  end

  def form_fields
    [[ 'infosheet_id', self.id ]]
  end

  def content_type
    document.content_type
  end

  def to_label
    document.original_filename
  end

  def to_link
    document.url
  end

  def generate_data
    File.read(document.path)
  end
end
