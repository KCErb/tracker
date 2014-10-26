class User < ActiveRecord::Base
  serialize :filters, Hash
end
