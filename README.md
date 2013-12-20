Companies REST/JSON API
=======================

This is a simple web service for demonstrational purposes. It is an interface to a database of company information, and consists of two parts, the REST API and the client. Usage of the API is discussed in [api_doc](/api_doc). Here, we will discuss implementation considerations.

The server
----------

The API is written in Ruby, using [sinatra][sinatra]. It uses ActiveRecord as its ORM, and the database backend is SQLite in the development environment and PostgreSQL in the production environment (when deployed to heroku). `app.rb` defines all the routes as well as the ActiveRecord models, and some helpers. The output is always JSON, and to keep the output generation in a separate "view", we use jbuilder templates.

Data is validated on the model level using ActiveRecords' `attr_protected`, `validates`, etc., so that we never write bad data to the database. We use the `save!` method with an exclamation mark when we save data, in order to make sure that an exception is raised if something goes wrong. All exceptions are caught in the `ExceptionHandling` class defined in `config.ru`, the response status code is set corresponding to the type of exception, and the error message is presented to the client in JSON format.

When uploading files, we expect the client to simply deliver the file, Base64-encoded, in the JSON data. The server then checks the MIME type, stores the content directly in the database and decodes and sends it back when requested. This method has several drawbacks:

 - 33% traffic overhead. Unacceptable for potentially very large files.
 - The whole file is kept in memory.
 - Large processing time, potentially causing timeouts in single-threaded systems.
 - Unnecessarily high traffic to the database, which is very unscalable.

I have chosen this method anyway because:

 - It is easy to implement in Ember.js
 - The whole file can be stored directly in the database, which is bad practice, but convenient on heroku where applications are not by default allowed to write files. One could use a storage system like S3, but I feel this is out of the scope of this exercise.
 - This app is for demonstration, and will never have more than a few clients at a time, so performance is not a problem.

In a real application, we might want to have multiple redundant database servers, and minimizing the traffic betwen master and slaves is very important.

The client
----------

The client is implemented in ember, using ember data v1. The Ember REST adapter takes care of all communication with the server, as long as the API is implemented the way Ember expects. This makes it easy to make a client app in an almost declarative fashion, defining models and relationships, routes, templates and controllers.

I styled it simply using bootstrap, but other than that, the client serves only to demonstrate the functionality of the API. There is not taken much caution regarding user experience, for example, I have not implemented error handling. If the user input causes the server to respond with an error message, nothing will happen.

The file upload facility is implemented using a `FileReader` object in a custom view, that reads a file and Base64-encodes it. I then bind the view to the Owner model so that the data is sent to the server when the owner is updated/created.

Authentication
--------------

In a real app like this, one would only let the client change records after authentication and authorization. There are several ways of implementing authentication in a REST application. The simplest way might be to use HTTP basic auth. This is RESTful, as it uses the existing functionality of the HTTP protocol, and it does not store application state on the server -- the bad part is that the client is responsable for sending login credentials with every request. We *must* make sure that these requests are sent only over HTTPS.

In a simple system, i would stick with HTTP basic auth, but in a more requiring system i would consider using token-based authentication, even just using OAuth.


[sinatra]: http://www.sinatrarb.com


<link rel="stylesheet" href="css/bootstrap.css"></link>
