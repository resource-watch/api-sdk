# This method enables the declaration of setter and getter methods for the
# 'rails' attributes, but tracking changes.
class Class
  # Custom accessor with support for dirty objects
  def changeable_attr_accessor(*args)
    args.each do |arg|
      # getter
      self.class_eval("def #{arg};@#{arg};end")
      # setter
      self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val==@#{arg};@#{arg}=val;end")
    end
  end
end


