**RubbyCop**'s installation is pretty standard:

```sh
$ gem install rubocop
```

If you'd rather install RubbyCop using `bundler`, don't require it in your `Gemfile`:

```rb
gem 'rubocop', require: false
```

RubbyCop's development is moving at a very rapid pace and there are
often backward-incompatible changes between minor releases (since we
haven't reached version 1.0 yet). To prevent an unwanted RubbyCop update you
might want to use a conservative version locking in your `Gemfile`:

```rb
gem 'rubocop', '~> 0.48.1', require: false
```
