class Contact < ActiveRecord::Base
  include YearlyModel
  attr_accessible :email, :family_name, :given_name, :list_order,
    :phone, :title, :year
  validates :email,
    :uniqueness => { :scope => :year, :case_sensitive => false },
    :format => { :with => EMAIL_REGEX },
    :length => { :maximum => 100 },
    :allow_blank => true
  validates :family_name,
    :presence => true,
    :length => { :maximum => 50 }
  validates :given_name,
    :presence => true,
    :length => { :maximum => 50 }
  validates :list_order,
    :presence => true,
    :numericality => { :only_integer => true }
  validates :title,
    :presence => true,
    :length => { :maximum => 50 }

  def full_name
    given_name + " " + family_name
  end
end