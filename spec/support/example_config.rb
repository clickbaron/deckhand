%w[Foo Bar Baz].each do |cls|
  eval "#{cls} = Class.new OpenStruct"
end

Deckhand.configure do

  model_label :pretty_name, :name, :tag

  model Foo do
    search_on :short_id, :exact
    search_on :name, :contains
    search_on :email, :contains

    show :bars
    exclude :password
    label { "#{name} <#{email}>" }
  end

  model Bar do
  end

  model Baz do
    search_on :recipient_email, :contains
    search_on :recipient_first_name, :contains
    search_on :recipient_last_name, :contains

    show :giver, :recipient, :subscription, :coupon
  end

end