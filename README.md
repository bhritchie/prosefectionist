Prosefectionist
===============

Prosefectionist (read: prose-fectionist) is a clean blogging platform written mostly in CoffeeScript and powered by Node.js and MongoDB. Its purpose is to provide myself a blogging platform that also develops my web skills. It is very much a work in progress. Note that it is very much a work in progress.

A demo site (my personal blog) is up at [prosefectionist.jit.su](http://prosefectionist.jit.su/).

Installation & Configuration
----------------------------

- Install node dependencies: "sudo npm install"
- Create config.ini file, as follows:

<pre>sitetitle=[Title for title tag]
sitename=<span class="sitename">[Title for page display]</span>
sitetag=[a brief description or tagline]
port=[port]
username=[admin username]
password=[admin password]
dbconnection=[a mongoURI, e.g. mongodb://[id]:[password]@[host]:[port]/[database]</pre>

- The site currently uses my own logos at public/images/, so you'll want to replace those 
- Run app: "node app.js"

Administration
--------------

- Access /admin to log in with username and password defined in config.ini. This allows the user to create, edit, and delete posts and pages, to edit and delete user comments, and to comment as the administrator (admin comments display differently).

Once logged in, "Administration" "Log Out" links will be available on the top right corner of the index page.

Current Features
----------------

Prosefectionist is in the early stages of development, but currently offers the following features:

- Create, edit, and delete posts
- Simple paging for blogs posts
- Create, edit, and delete pages
- Minimal commenting system (no user log-in), with basic input validation and bot-resistance.
- Administrator ability to edit and delete comments, and admin comments have special highlighting
