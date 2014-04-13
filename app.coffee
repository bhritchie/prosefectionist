#Brendan Ritchie, April 2014
#www.prosefectionist.com

#rough installation instructions:
#install node dependencies: "sudo npm install"
#Set admin username and password in config.ini, and port (default 3000)
#Have MongoDB running with a database called "blog"
#Run app: "node app.js"
#Find app running at [host]:[port]
#The files have a lot of site-specific info right now - for example there is currently a lot of repitition in the layout files, which all have my (Brendan's) own personal tagline


#for Prod:
#port should be 80
#turn off pretty printing of html

iniparser = require 'iniparser'
config = iniparser.parseSync './config.ini'

#TEST THE CONFIG.INI LOADING

#Admin username and password in congif.ini
username = config.username
password = config.password

console.log username
console.log password

#does express import this anyway?
http = require 'http'

express = require 'express'
app = express()

mongo = require 'mongodb'
monk = require 'monk'
#async = require 'node-async'
mongoStore = require('connect-mongo')(express) 
db = monk 'localhost:27017/blog'

app.use express.static './public/'
app.set 'view engine', 'jade'
app.set 'views', './views'

app.locals.pretty = true	#only for dev

app.use express.logger {format:':remote-addr :method :url'}

app.use express.bodyParser()

app.use express.cookieParser 'baggins'

app.use express.session {
	store: new mongoStore {
		db: 'blog',
		host: '127.0.0.1',
		port: 27017
		}
	}

app.use app.router

pageskip = 5 #number of posts per page (including first/index page)

#START WITH ROUTES TO HANDLE ERRORS

#To test 500 errors:
app.get '/fail/?', (req, res) ->
	fail()

#500 errors
app.use (error, req, res, next) ->
	res.status 500
	res.render 'error.jade', {
		error: '500',
		message: 'The Prosefectionist writes prose, not code.',
		errorreport: error
		}

#404 errors
app.use (req, res) ->
	res.status(404);
	res.render 'error.jade', {
		error: '404',
		message: 'The Prosefectionist can write, but he can\'t find your page.'
		}

#LOGIN
app.get '/login/?', (req, res) ->
	res.render 'login'


#LOGIN
app.get '/ajaxtest/?', (req, res) ->
	res.send 'Hello from Ajax'


app.post '/inpagecomment/:id', (req, res) ->

	console.log 'hello there'
	console.log req.body.admin
	console.log req.body.name

	newcomment = {}

	newcomment.post = req.params.id
	newcomment.date = new Date()
	newcomment.comment = req.body.comment

	if req.body.admin is true
		newcomment.admin = true
		newcomment.name = username
		#newcomment.email = useremail #HAVE TO DEFINE THIS ABOVE	
	else
		newcomment.admin = false #indent for else later
		newcomment.name = req.body.name #indent for else
		#newcomment.email = req.body.email

	comments = db.get 'comments'

	#test the error by shutting off the database
	comments.insert newcomment, (err, doc) ->
			res.send 'Error saving comment.' if err
			console.log doc
			doc.time = doc.date.getUTCHours() + ':' + doc.date.getUTCMinutes()
			doc.day = doc.date.toLocaleDateString()
			console.log doc
			res.send doc		
	#res.send 'Comment saved.'
	#send system message with redirect
	#res.redirect 303, "/post/#{req.params.id}"




#maybe test errors by shutting off mongo server?
#Make this return to the post page for the new post - how can I insert and get id?
app.post '/login', (req, res) ->

	if req.body.username is username and req.body.password is password
		req.session.admin = true
		#want a system message here with redirect to home
		res.redirect 303, '/'
	else
		#want a system message here and redirect to home
		res.redirect 303, '/'


app.get '/logout', (req, res) ->
	req.session.destroy()
	res.redirect 303, '/'


#ABOUT
app.get '/about/?', (req, res) ->
	res.render 'about'


#INDEX
app.get '/', (req, res) ->

	results = null
	totalposts = null
	blogposts = db.get 'posts'

	blogposts.find {}, {limit: pageskip, sort: {date: -1}}, (e,docs) ->
		results = docs
		#console.log docs
		complete()

	blogposts.count {}, (e,count) ->
		totalposts = count
		complete()

	complete = () ->
		if results isnt null and totalposts isnt null
			res.render 'index', {
				posts: results,
				title:config.title,
				numposts: totalposts,
				admin: req.session.admin
			}

app.get '/page/1/?', (req, res) ->
	res.redirect 303, '/'

#NEW POSTS
#fix the textarea stuff - why does it work differently than other inputs, or are they all suposed to be like textarea?
#audd 'auth as second parameter to use basic auth
app.get '/newpost/?', (req, res) ->
	if req.session.admin
		res.render 'newpost' 
	else
		#provide system message with redirection
		res.redirect 303, '/'		


#maybe test errors by shutting off mongo server?
#Make this return to the post page for the new post - how can I insert and get id?
app.post '/newpost', (req, res) ->
	if req.session.admin
		blogposts = db.get 'posts'
		blogposts.insert {
			'title': req.body.posttitle,
			'body': req.body.postbody,
			'date': new Date()
			}, (err, doc) ->
				res.send 'Error adding post.' if err
		res.send 'Post created.'
	else
		#send system message with redirect
		res.redirect 303, '/'

app.get '/editpost/:id', (req, res) ->
	if req.session.admin
		blogposts = db.get 'posts'
		blogposts.find {_id: req.params.id}, (e,docs) ->
			res.render 'editpost', {
				posttitle: docs[0].title,
				postbody: docs[0].body,
				postid: docs[0]._id
			}
	else
		#send system message with redirect
		res.redirect 303, '/'

app.post '/editpost/:id', (req, res) ->
	if req.session.admin
		blogposts = db.get 'posts'
		blogposts.update {_id: req.params.id}, {$set: {
			'title': req.body.posttitle,
			'body': req.body.postbody
			}}, (err, doc) ->
				res.send 'Error editing post.' if err
		#res.send 'Post edited.'

		#why am i sorting and getting limit here?
		blogposts.find {_id: req.params.id}, {limit:5, sort: {date: -1}}, (e,docs) ->
			res.render 'post', {
					posttitle: docs[0].title,
					postbody: docs[0].body,
					postid: docs[0]._id
			}
	else
		#send system message with redirect
		res.redirect 303, '/'


app.get '/comment/:id', (req, res) ->
	blogposts = db.get 'posts'
	blogposts.find {_id: req.params.id}, (e,docs) ->
		res.render 'comment', {
			posttitle: docs[0].title,
			#postbody: docs[0].body,
			postid: docs[0]._id,
			admin: req.session.admin
		}

#maybe test errors by shutting off mongo server?
#Make this return to the post page for the new post - how can I insert and get id?
app.post '/comment/:id', (req, res) ->

	newcomment = {}

	newcomment.post = req.params.id
	newcomment.date = new Date()
	newcomment.comment = req.body.comment

	if req.body.admin
		newcomment.admin = true
		newcomment.name = username
		#newcomment.email = useremail #HAVE TO DEFINE THIS ABOVE	
	else
		newcomment.admin = false
		newcomment.name = req.body.name
		#newcomment.email = req.body.email

	comments = db.get 'comments'

	comments.insert newcomment, (err, doc) ->
			res.send 'Error saving comment.' if err

	#send system message woth redirect
	res.redirect 303, "/post/#{req.params.id}"

app.get '/deletepost/:id', (req, res) ->
	if req.session.admin
		blogposts = db.get 'posts'
		blogposts.remove {_id: req.params.id}, (err, doc) ->
				res.send 'Error deleting post.' if err
		comments = db.get 'comments'
		comments.remove {post: req.params.id}, (err, doc) ->
				res.send 'Error deleting comments.' if err
		#could this be faster if I do the redirect first and then send the delet requests? but they shouldn't block anyway I think...
		#send system message with redirect
		res.redirect 303, '/'
	else
		#send system message with redirect
		res.redirect 303, '/'


app.get '/deletecomment/:post/:comment', (req, res) ->
	if req.session.admin
		#console.log req.params
		comments = db.get 'comments'
		comments.remove {_id: req.params.comment}, (err, doc) ->
				res.send 'Error deleting comment.' if err
		#send system message with redirect to oroginal pst
		res.redirect 303, '/post/' + req.params.post
	else
		#send system message with redirect to original post
		res.redirect 303, '/post/' + req.params.post


#EDIT COMMENT GET
app.get '/editcomment/:post/:comment', (req, res) ->
	if req.session.admin
		comments = db.get 'comments'
		comments.find {post: req.params.post, _id: req.params.comment}, (e,docs) ->
			console.log docs			
			res.render 'editcomment', {
				name: docs[0].name,
				email: docs[0].email,
				comment: docs[0].comment,
				commentid: docs[0]._id,
				postid: req.params.post
			}
	else
		#send system message with redirect
		res.redirect 303, '/'

#EDIT COMMENT POST
app.post '/editcomment/:post/:comment', (req, res) ->
	if req.session.admin
		comments = db.get 'comments'
		comments.update {_id: req.params.comment}, {$set: {
			'name': req.body.name,
			'email': req.body.email,
			'comment': req.body.comment
			}}, (err, doc) ->
				res.send 'Error editing comment.' if err
		#res.send 'Post edited.'

		#why am i sorting and getting limit here?
		res.redirect 303, '/post/' + req.params.post
	else
		#send system message with redirect
		res.redirect 303, '/'


#INDIVIDUAL POST
app.get '/post/:id', (req, res) ->

	post = null
	comments = null
	#commentid = null

	blogposts = db.get 'posts'
	#remove limit and sort throughout section
	blogposts.find {_id: req.params.id}, {limit:5, sort: {date: -1}}, (e,docs) ->
		post = docs
		complete()

	commentsColl = db.get 'comments'
	commentsColl.find {post: req.params.id}, {sort: {date: 1}}, (e,docs) ->
		comments = docs	
		#commentid = docs[0]._id
		complete()

	complete = () ->		
		if post isnt null and comments isnt null
			if isEmptyObject(comments)
				comments = false
			res.render 'post', {
					posttitle: post[0].title,
					postbody: post[0].body,
					postid: post[0]._id,
					postdate: post[0].date.toLocaleDateString(),
					admin: req.session.admin,
					comments: comments
			}

#PAGING
#handle case of /page/
#handle trailing / after page number
#route page/1/? to /
app.get '/page/:id', (req, res) ->
	
	#redirects but has the styling and image issue
	if (isNaN req.params.id) or (req.params.id % 1 isnt 0) or (req.params.id < 1)
		res.status(404);
		res.render 'error.jade', {
			error: '404',
			message: 'The Prosefectionist can write, but he can\'t find your page.'
		}

	results = null
	totalposts = null
	prevpage = (req.params.id - 1)
	nextpage = null

	blogposts = db.get 'posts'

	blogposts.find {}, {limit: pageskip, sort: {date: -1}, skip: (req.params.id - 1) * pageskip}, (e,docs) ->
		results = docs
		complete()

	blogposts.count {}, (e,count) ->
		totalposts = count 
		if count > (req.params.id * pageskip)
			nextpage = parseInt(req.params.id) + 1
		complete()

	complete = () ->
		if results isnt null and totalposts isnt null
			res.render 'page', {
				returnedposts: results,
				title:config.title,
				currpage: req.params.id,
				message:config.message,
				#numposts: totalposts,
				prevpage: prevpage,
				nextpage: nextpage
			}


#UTILITY FUNCTIONS

#Check for empty object
isEmptyObject = (obj) ->
  name = undefined
  for name of obj
    return false
  true



http.createServer(app).listen config.port, ->
	console.log "Express app started on #{config.port}"
