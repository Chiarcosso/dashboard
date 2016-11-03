# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
ActiveRecord::Base.connection.execute("TRUNCATE people")
ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1")

person = Person.new
person.name = 'Fabio'
person.surname = 'Boccacini'
person.notes = "He's a nice guy!"
person.save

ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
ActiveRecord::Base.connection.execute("TRUNCATE users")
ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1")

user = User.new
user.email = "fabio.boccacini@chiarcosso.com"
user.password = "test1234"
user.person = person
user.save
user.add_role "admin"

ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
ActiveRecord::Base.connection.execute("TRUNCATE article_categories")
ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1")

ArticleCategory.create! :name => 'Officina'
ArticleCategory.create! :name => 'Dotazione'
ArticleCategory.create! :name => 'Ufficio'
