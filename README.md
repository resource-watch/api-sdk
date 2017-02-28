# Resource Watch API SDK

This gem provides an ActiveModel interface for connecting ruby applications with the Resource Watch API.

## Usage

Build with `gem build rw_api_sdk.gemspec` and install it with `gem install api_sdk-*.gem`. Then, just declare it in your Gemfile.

To load the gem in a irb session type `bundle && bundle exec irb`. Then you just need to `require "api_sdk"`.

Usage

This gem exposes several classes in the module APISdk, corresponding to different Resource Watch API endpoints. Datasets are exposed as the APISdk::Dataset class. Right now, you can do several things with a Dataset &mdash;but only the mandatory fields are supported:


Find a dataset in the API:


```
> require 'api_sdk'
=> true 
> dataset = APISdk::Dataset.find("1f6b48e6-a32e-4c0b-8b86-8285849bab63")      
=> #<APISdk::Dataset:0x007f89f872fb58 @changed_attributes={}, @id="1f6b48e6-a32e-4c0b-8b86-8285849bab63", @name="Old name", @connector_type="rest", @provider="cartodb", @connector_url="https://insights.cartodb.com/api/v2/sql?q=select * FROM public.cait_2_0_country_ghg_emissions_toplow2011", @application=["rw"], @errors=#<ActiveModel::Errors:0x007f89f872eeb0 @base=#<APISdk::Dataset:0x007f89f872fb58 ...>, @messages={}, @details={}>, @persisted=true, @previously_changed={}>
```

You can modify its attributes:


```
> dataset.name = "New name"
=> "New name" 
```

But as the name has changed, now its attributes are not equal to those of the API dataset.


```
> dataset.persisted?
=> false
```

You can inspect the changes and rollback them:
```
> dataset.changes
=> {"name" => ["Old name", "New name"]}
> dataset.rollback!
=> ["name"]
> dataset.name
=> "Old name"
```

So now there are no differences between your object and the API dataset.


```
> dataset.persisted?
=> true
> a.changes
=> {}
```

The changes you make are validated:


```
> dataset.name = nil
> dataset.valid?
=> false
> dataset.errors.to_hash
=> {:name => ["can't be blank"]}
```

When you are done, you can update the object and persist it to the API

``` 
> dataset.name = "A different name"
> dataset.valid?
=> true
> dataset.update
=> #<APISdk::Dataset:0x007fefaa537270 @changed_attributes={}, @id="1f6b48e6-a32e-4c0b-8b86-8285849bab63", @name="A different name", @connector_type="rest", @provider="cartodb", @connector_url="https://insights.cartodb.com/api/v2/sql?q=select * FROM public.cait_2_0_country_ghg_emissions_toplow2011", @application=["rw"], @errors=#<ActiveModel::Errors:0x007fefaa536758 @base=#<APISdk::Dataset:0x007fefaa537270 ...>, @messages={}, @details={}>, @persisted=true, @previously_changed={}, @validation_context=nil>                                                       

```

It will again reflect its persisted state:

``` 
> dataset.persisted?
=> true
```

Add legends to csv datasets with a properly formatted object.

```
a.legend = {"lat"=>"latitude", "date"=>["ISO", "dates", "here"], "long"=>"longitude", "region"=>["regions", "here"], "country"=>["ESP"]}
```															     
Create a /de novo/ dataset:

```
a = APISdk::Dataset.new(
  :name           => "Example dataset",
  :connector_type => "document",
  :provider       => "csv",
  :application    => ["rw"],
  :connector_url  => "",
  :subtitle       => "subtitulo",
  :legend         => {
    "lat"           => "latitude",
    "long"          => "longitude"
  }
)

a.token = "A proper CT API JWT"
a.create
```



TODO: refactoring, creating of _de novo_ datasets, destroying, adding fields
