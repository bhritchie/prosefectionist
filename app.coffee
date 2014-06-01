#Brendan Ritchie, April 2014
#https://github.com/bhritchie/prosefectionist

#When in prodMode, use db connection string from config.ini
prodMode = false

iniparser = require 'iniparser'
config = iniparser.parseSync './config.ini'

#Site name and tag are loaded from config.ini
sitetitle = config.sitetitle
sitename = config.sitename
sitetag = config.sitetag


#LOAD FROM INI.CONFIG
latestwhitelist = "prosefectionist.com"

#Admin username and password are loaded from congif.ini
username = config.username
password = config.password

#Database connection parameter is loaded from config.ini
dbconnection = config.dbconnection

#Load port from config.ini - for Prod use 80
port = config.port

http = require 'http'
express = require 'express'
app = express()

#Turn off pretty printing for prod
app.locals.pretty = true

mongo = require 'mongodb'
monk = require 'monk'
#async = require 'node-async'
mongoStore = require('connect-mongo')(express) 


app.use express.static './public/'
app.set 'view engine', 'jade'
app.set 'views', './views'

app.use express.logger {format:':remote-addr :method :url'}

app.use express.bodyParser()

app.use express.cookieParser 'baggins'


#In prodMode use db connection from config.ini
if prodMode
	db = monk dbconnection
	app.use express.session {
		store: new mongoStore {
			url: dbconnection
			}
		}
#else use local mongo server
else
	db = monk 'localhost:27017/blog'
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


#Get latest post titles in JSON
app.get '/latest', (req, res) ->
	res.header "Access-Control-Allow-Origin", latestwhitelist
	res.header "Access-Control-Request-Method", "GET"
	blogposts = db.get 'posts'
	blogposts.find {}, {limit: 5, sort: {date: -1}}, (e,docs) ->
		res.send docs


#Get latest post titles in JSON
app.get '/latest', (req, res) ->
	res.header "Access-Control-Allow-Origin", latestwhitelist
	res.header "Access-Control-Request-Method", "GET"
	blogposts = db.get 'posts'
	blogposts.find {}, {limit: 5, sort: {date: -1}}, (e,docs) ->
		res.send docs


#Allow admin to download all posts for archival purposes
app.get '/archive', (req, res) ->


#NEED TO COMBINE THE RESULTS FOR A SINGLE RESPONSE

	if req.session.admin
		pageresults = null
		postresults = null

		sitepages = db.get 'pages'

		sitepages.find {}, {sort: {sequence: 1}}, (e,docs) ->
			pageresults = docs
			complete()

		blogposts = db.get 'posts'
		blogposts.find {}, {sort: {date: -1}}, (e,docs) ->
			postresults = docs
			complete()

		complete = () ->
			if pageresults isnt null and postresults isnt null
				res.send results

	else
		#provide system message with redirection
		res.redirect 303, '/'



#BEGIN LOGIN AND ADMIN ROUTES
app.get '/login/?', (req, res) ->
	if req.session.admin
		res.redirect 303, '/admin'
	else
		#provide system message with redirection
		res.render 'login'

#maybe test errors by shutting off mongo server?
#Make this return to the post page for the new post - how can I insert and get id?
app.post '/login', (req, res) ->

	if req.body.username is username and req.body.password is password
		req.session.admin = true
		#want a system message here with redirect to home
		res.redirect 303, '/admin'
	else
		#want a system message here and redirect to home
		res.redirect 303, '/'

app.get '/logout', (req, res) ->
	req.session.destroy()
	res.redirect 303, '/'

app.get '/admin/?', (req, res) ->
	if req.session.admin
		res.render 'admin'
	else
		#provide system message with redirection
		res.redirect 303, '/login'

#END LOGIN AND ADMIN ROUTES


app.post '/inpagecomment/:id', (req, res) ->

	newcomment = {}

	newcomment.post = req.params.id
	newcomment.date = new Date()
	newcomment.comment = req.body.comment

	if req.body.admin is 'true'
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
			doc.time = doc.date.getHours() + ':' + doc.date.getMinutes()
			doc.day = doc.date.toLocaleDateString()
			res.send doc		
	#res.send 'Comment saved.'
	#send system message with redirect
	#res.redirect 303, "/post/#{req.params.id}"




#ABOUT
#app.get '/about/?', (req, res) ->
#	res.render 'about'


#NEW PAGES
#fix the textarea stuff - why does it work differently than other inputs, or are they all suposed to be like textarea?
app.get '/newpage/?', (req, res) ->
	if req.session.admin
		res.render 'newpage' 
	else
		#provide system message with redirection
		res.redirect 303, '/'	


#maybe test errors by shutting off mongo server?
#Make this return to the post page for the new post - how can I insert and get id?
app.post '/newpage', (req, res) ->
	if req.session.admin
		sitepages = db.get 'pages'
		sitepages.insert {
			'shortname': req.body.pagetitleshort,
			'longname': req.body.pagetitlelong,
			'sequence': req.body.pagesequence,
			'body': req.body.pagebody,
			'date': new Date()
			}, (err, doc) ->
				res.send 'Error adding page.' if err
		res.redirect 303, '/'
	else
		#send system message with redirect
		res.redirect 303, '/'

app.get '/editpage/:id', (req, res) ->
	if req.session.admin
		sitepages = db.get 'pages'
		sitepages.find {_id: req.params.id}, (e,docs) ->
			res.render 'editpage', {
				pagetitleshort: docs[0].shortname,
				pagetitlelong: docs[0].longname,
				pagesequence: docs[0].sequence,
				pagebody: docs[0].body,
				pageid: docs[0]._id
			}
	else
		#send system message with redirect
		res.redirect 303, '/'

app.post '/editpage/:id', (req, res) ->
	if req.session.admin
		sitepages = db.get 'pages'
		sitepages.update {_id: req.params.id}, {$set: {
			'shortname': req.body.pagetitleshort,
			'longname': req.body.pagetitlelong,
			'body': req.body.pagebody
			}}, (err, doc) ->
				res.send 'Error editing page.' if err
		#res.send 'Post edited.'

		#why am i sorting and getting limit here?
		#redirect this to the real pages link - for some reason no longer has admin links eg
		sitepages.find {_id: req.params.id}, {limit:5, sort: {date: -1}}, (e,docs) ->
			res.render 'pages', {
					pagetitleshort: docs[0].shortname,
					pagetitlelong: docs[0].longname,
					pagesequence: docs[0].sequence,
					pagebody: docs[0].body,
					pageid: docs[0]._id
			}
	else
		#send system message with redirect
		res.redirect 303, '/'

app.get '/deletepage/:id', (req, res) ->
	if req.session.admin
		sitepages = db.get 'pages'
		sitepages.remove {_id: req.params.id}, (err, doc) ->
				res.send 'Error deleting page.' if err
		#could this be faster if I do the redirect first and then send the delet requests? but they shouldn't block anyway I think...
		#send system message with redirect
		res.redirect 303, '/'
	else
		#send system message with redirect
		res.redirect 303, '/'

#INDIVIDUAL PAGE
app.get '/pages/:id', (req, res) ->

	sitepages = db.get 'pages'
	#remove limit and sort throughout section
	sitepages.find {_id: req.params.id}, {limit:5, sort: {date: -1}}, (e,docs) ->
		page = docs
		res.render 'pages', {
				pagetitlelong: page[0].longname,
				pagebody: page[0].body,
				pageid: page[0]._id,
				pagedate: page[0].date.toLocaleDateString(),
				admin: req.session.admin
		}


#INDEX
app.get '/', (req, res) ->

	pageresults = null
	postresults = null
	totalposts = null

	sitepages = db.get 'pages'

	sitepages.find {}, {sort: {sequence: 1}}, (e,docs) ->
		#ONLY FETCH THE SHORT NAME, ID, AND SEQUENCE!
		#Can't figure out how to drop this so might need to strip the pageresults a bit before passing to jade...
		pageresults = docs
		#console.log pageresults
		complete()

	blogposts = db.get 'posts'
	blogposts.find {}, {limit: pageskip, sort: {date: -1}}, (e,docs) ->
		postresults = docs
		complete()

	blogposts.count {}, (e,count) ->
		totalposts = count
		complete()

	complete = () ->
		if pageresults isnt null and postresults isnt null and totalposts isnt null
			res.render 'index', {
				sitetitle: sitetitle,
				sitename: sitename,
				sitetag: sitetag,
				pages: pageresults,
				posts: postresults,
				title:config.title,
				numposts: totalposts,
				admin: req.session.admin
			}

app.get '/page/1/?', (req, res) ->
	res.redirect 303, '/'

#NEW POSTS
#fix the textarea stuff - why does it work differently than other inputs, or are they all suposed to be like textarea?
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
		res.redirect 303, '/'
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
	#pageresults = null
	#commentid = null

	sitepages = db.get 'pages'

	#sitepages.find {}, {sort: {sequence: 1}}, (e,docs) ->
		#ONLY FETCH THE SHORT NAME, ID, AND SEQUENCE!
		#Can't figure out how to drop this so might need to strip the pageresults a bit before passing to jade...
		#pageresults = docs
		#console.log pageresults
		#complete()


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
					#pages: pageresults,
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



http.createServer(app).listen port, ->
	console.log "Express app started on port #{port}"
