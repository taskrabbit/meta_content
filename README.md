# MetaContent

Store document values in MySQL in a separate key/value table.
I'm sure this exists already, but we couldn't find one.

## Installation

Add this line to your application's Gemfile:

    gem 'meta_content'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install meta_content

## Migration

```ruby
class CreateTaskMeta < ActiveRecord::Migration
  def up
    create_table :tasks_meta do |t|
      t.integer :object_id, :null => false
      t.string  :namespace, :null => false
      t.string  :lookup,    :null => false
      t.string  :value
      t.integer :int_value
    end

    add_index :tasks_meta, [:object_id, :namespace, :lookup], unique: true
    add_index :tasks_meta, :object_id
  end
  
  def down
    drop_table :tasks_meta
  end
end
```

## Model

```ruby
class Task < ActiveRecord::Base

  meta do
    string  :name
    integer :price
    float   :hours, :default => 1.0
  end
  
  meta :timing do
    datetime :start_at
    string :description
    boolean :flexible, :default => false
  end
  
end
```

## Usage

This gives getters and setters for everything defined:

```ruby
task = Task.new

task.name = "Store meta info"
task.price = 20
task.hours = 3.2

task.timing_start_at = 3.hours.from_now
task.timing_description = "Tonight or otherwise by Friday"
task.timing_flexible = true

task.save!
```

Everything gets saved in the `tasks_meta` table. Updating and saving updates those rows.
overall, it works like they were regular columns.
