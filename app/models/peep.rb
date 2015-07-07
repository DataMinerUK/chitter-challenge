require 'data_mapper'
require 'dm-validations' # aren't these required in data_mapper_setup ?

class Peep
  include DataMapper::Resource

  property :id,         Serial
  property :text,       Text, :required => true
  property :time_stamp, DateTime
  property :reply,      Boolean, :default  => false
  property :replied_id, Integer
  property :replied_to, String

  belongs_to :user, :required => true

end

# what you really want here is a many-to-many connection with itself http://datamapper.org/docs/associations.html 
