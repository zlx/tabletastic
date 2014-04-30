# Tabletastic

http://travis-ci.org/jgdavey/tabletastic.png

## NOTICE: No longer maintained

I haven't used this gem in years, and am no longer actively contributing to
it. I am more than willing to give commit rights to anyone that wants to
maintain it.

## Introduction

Inspired by the projects table_builder and formtastic, I realized how often I
created tables for my active record collections. This is my attempt to
simplify this (the default scaffold):

    <table>
      <tr>
        <th>Title</th>
        <th>Body</th>
        <th>Author Id</th>
      </tr>
      <% for post in @posts %>
        <tr>
          <td><%=h post.title %></td>
          <td><%=h post.body %></td>
          <td><%=h post.author_id %></td>
          <td><%= link_to "Show", post %></td>
          <td><%= link_to "Edit", edit_post_path(post) %></td>
          <td><%= link_to "Destroy", post, :confirm => 'Are you sure?', :method => :delete %></td>
          </tr>
      <% end %>
    </table>

into this:

    <%= table_for(@posts) do |t|
          t.data :actions => :all
        end %>

and still output the same effective results, but with all the semantic
goodness that tabular data should have, i.e. a `thead` and `tbody` element.

## Installation

In your Rails project, Gemfile:
    gem "tabletastic"

Or, for if you're behind the times, as a plugin:
    script/plugin install git://github.com/jgdavey/tabletastic.git

Optionally, you can create an initializer at
config/initializers/tabletastic.rb with the following:
    Tabletastic.default_table_block = lambda {|table| table.data :actions => :all }

## Usage

### table_for

example:

```ruby
table_for @admin_users, html: { class: '' } do |t|
  ...
end
```

+ Use `Tabletastic.default_table_html` to config the table default html

### cell

example:

```ruby
table_for @admin_users do |t|
  t.cell(:login, width: '20%', sort: true) { |user| user.great_login }
end
```

+ `width`: assign the width of the th tag
+ `sort`: used for sort, will pass params like `{"q": {"s": "login asc"}}`
+ `proc`: used for replace the default content in td tag

## Internationalization (I18n)

Tabletastic has some i18n-features enabled by default.

Here is an example of locales:

    en:
      tabletastic:
          actions:
              show: "See"
              edit: "Edit"
              destroy: "Remove"
              confirmation: "Are you sure?"
          models:
              comment:
                  title: "Title"

## Default Options and Tabletastic initializer

As of version 0.2.0, you can now setup some of your own defaults in an
initializer file.

For example, create a file called tabletastic.rb in your config/initializers
folder.

Within that file, there are several defaults that you can setup for yourself,
including:

    Tabletastic.default_table_html
    Tabletastic.default_table_block

Both of these options are setup up so that inline options will still override
whatever they are set to, but providing them here will save you some code if
you commonly reuse options.

By default, `default_table_html` is simple an empty hash `{}`. By providing
your own defaults, you can ensure that all of your tables have a specific html
`class` or `cellspacing`, or whatever.

If `Tabletastic.default_table_html` is set to `{:cellspacing => 0, :class =>
'yowza'}`, then all tabletastic tables will have this html by default, unless
overridden:

    table_for(@posts) do |t|  # body of block removed for brevity

will produce:

    <table class="yowza" cellspacing="0" id="posts">

Similarly, all of those calls to `table_for` can get boring since you might be
using the same block every time. The option `default_table_block` lets you set
a default lambda so that you can omit the block with `table_for`. Since by
default `default_table_block` is set to `lambda{|table| table.data}`, the
following:

    <%= table_for(@posts) %>

will be the same as

    <%= table_for(@posts) do |t|
          t.data
        end %>

However, just like `default_table_html` , you can set a different block in the
initializer file for your block to default to.

For example:

    Tabletastic.default_table_block = lambda {|table| table.data :actions => :all }

will make the following equivalent:

    <%= table_for(@posts) %>

    <%= table_for(@posts) do |t|
          t.data :actions => :all
        end %>

And to omit those action links, you can just use `table_for` the old-fashioned
way:

    <%= table_for(@posts) do |t|
          t.data
        end %>

## Note on Patches/Pull Requests

*   Fork the project.
*   Make your feature addition or bug fix.
*   Add tests for it. This is important so I don't break it in a future
    version unintentionally.
*   Commit, do not mess with rakefile, version, or changelog. (if you want to
    have your own version, that is fine but bump version in a commit by itself
    I can ignore when I pull)
*   Send me a pull request. Bonus points for topic branches.


## Copyright

Copyright (c) 2011 Joshua Davey. See LICENSE for details.
