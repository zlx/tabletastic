## Tabletastic 使用

### table_for

example:

```ruby
table_for @admin_users, html: { class: '' } do |t|
  ...
end
```

+ 配置 `Tabletastic.default_table_html` 来指定 table 的默认样式

### cell

example:

```ruby
table_for @admin_users do |t|
  t.cell(:login, width: '20%', sort: true, cell_html: { }, heading_html: {}) { |user| user.great_login }
end
```

+ `width`: 指定 head 的宽度，对应于 th 里面的 width
+ `cell_html`: 指定 tbody 里面 td 的样式
+ `heading_html`: 指定 thead 里面 td 的样式
+ `sort`: 集成类似于 ransack 的 sort_link，传递 `{"q": {"s": "login asc"}}` 参数
+ `block`: 替换掉默认显示的内容 `user.login`

### 操作
对于 actions 采用 block 的形式

```ruby
<%= t.cell(:action) do |user| %>
  <%= render_edit_link(user) %>
  <%= render_block_user_link(user) %>
<% end %>
```

### 已知的 Bug

`<%= t.cell(:comments_count) { |q| q.comments.count } %>`

这样会显示不出结果,要改成

`<%= t.cell(:comments_count) { |q| q.comments.count.to_s } %>`
