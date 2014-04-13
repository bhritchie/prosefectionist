// Generated by CoffeeScript 1.6.3
(function() {
  var app, config, db, express, http, iniparser, isEmptyObject, mongo, mongoStore, monk, pageskip, password, username;

  iniparser = require('iniparser');

  config = iniparser.parseSync('./config.ini');

  username = config.username;

  password = config.password;

  console.log(username);

  console.log(password);

  http = require('http');

  express = require('express');

  app = express();

  mongo = require('mongodb');

  monk = require('monk');

  mongoStore = require('connect-mongo')(express);

  db = monk('localhost:27017/blog');

  app.use(express["static"]('./public/'));

  app.set('view engine', 'jade');

  app.set('views', './views');

  app.locals.pretty = true;

  app.use(express.logger({
    format: ':remote-addr :method :url'
  }));

  app.use(express.bodyParser());

  app.use(express.cookieParser('baggins'));

  app.use(express.session({
    store: new mongoStore({
      db: 'blog',
      host: '127.0.0.1',
      port: 27017
    })
  }));

  app.use(app.router);

  pageskip = 5;

  app.get('/fail/?', function(req, res) {
    return fail();
  });

  app.use(function(error, req, res, next) {
    res.status(500);
    return res.render('error.jade', {
      error: '500',
      message: 'The Prosefectionist writes prose, not code.',
      errorreport: error
    });
  });

  app.use(function(req, res) {
    res.status(404);
    return res.render('error.jade', {
      error: '404',
      message: 'The Prosefectionist can write, but he can\'t find your page.'
    });
  });

  app.get('/login/?', function(req, res) {
    return res.render('login');
  });

  app.get('/ajaxtest/?', function(req, res) {
    return res.send('Hello from Ajax');
  });

  app.post('/inpagecomment/:id', function(req, res) {
    var comments, newcomment;
    console.log('hello there');
    console.log(req.body.admin);
    console.log(req.body.name);
    newcomment = {};
    newcomment.post = req.params.id;
    newcomment.date = new Date();
    newcomment.comment = req.body.comment;
    if (req.body.admin === true) {
      newcomment.admin = true;
      newcomment.name = username;
    } else {
      newcomment.admin = false;
      newcomment.name = req.body.name;
    }
    comments = db.get('comments');
    return comments.insert(newcomment, function(err, doc) {
      if (err) {
        res.send('Error saving comment.');
      }
      console.log(doc);
      doc.time = doc.date.getUTCHours() + ':' + doc.date.getUTCMinutes();
      doc.day = doc.date.toLocaleDateString();
      console.log(doc);
      return res.send(doc);
    });
  });

  app.post('/login', function(req, res) {
    if (req.body.username === username && req.body.password === password) {
      req.session.admin = true;
      return res.redirect(303, '/');
    } else {
      return res.redirect(303, '/');
    }
  });

  app.get('/logout', function(req, res) {
    req.session.destroy();
    return res.redirect(303, '/');
  });

  app.get('/about/?', function(req, res) {
    return res.render('about');
  });

  app.get('/', function(req, res) {
    var blogposts, complete, results, totalposts;
    results = null;
    totalposts = null;
    blogposts = db.get('posts');
    blogposts.find({}, {
      limit: pageskip,
      sort: {
        date: -1
      }
    }, function(e, docs) {
      results = docs;
      return complete();
    });
    blogposts.count({}, function(e, count) {
      totalposts = count;
      return complete();
    });
    return complete = function() {
      if (results !== null && totalposts !== null) {
        return res.render('index', {
          posts: results,
          title: config.title,
          numposts: totalposts,
          admin: req.session.admin
        });
      }
    };
  });

  app.get('/page/1/?', function(req, res) {
    return res.redirect(303, '/');
  });

  app.get('/newpost/?', function(req, res) {
    if (req.session.admin) {
      return res.render('newpost');
    } else {
      return res.redirect(303, '/');
    }
  });

  app.post('/newpost', function(req, res) {
    var blogposts;
    if (req.session.admin) {
      blogposts = db.get('posts');
      blogposts.insert({
        'title': req.body.posttitle,
        'body': req.body.postbody,
        'date': new Date()
      }, function(err, doc) {
        if (err) {
          return res.send('Error adding post.');
        }
      });
      return res.send('Post created.');
    } else {
      return res.redirect(303, '/');
    }
  });

  app.get('/editpost/:id', function(req, res) {
    var blogposts;
    if (req.session.admin) {
      blogposts = db.get('posts');
      return blogposts.find({
        _id: req.params.id
      }, function(e, docs) {
        return res.render('editpost', {
          posttitle: docs[0].title,
          postbody: docs[0].body,
          postid: docs[0]._id
        });
      });
    } else {
      return res.redirect(303, '/');
    }
  });

  app.post('/editpost/:id', function(req, res) {
    var blogposts;
    if (req.session.admin) {
      blogposts = db.get('posts');
      blogposts.update({
        _id: req.params.id
      }, {
        $set: {
          'title': req.body.posttitle,
          'body': req.body.postbody
        }
      }, function(err, doc) {
        if (err) {
          return res.send('Error editing post.');
        }
      });
      return blogposts.find({
        _id: req.params.id
      }, {
        limit: 5,
        sort: {
          date: -1
        }
      }, function(e, docs) {
        return res.render('post', {
          posttitle: docs[0].title,
          postbody: docs[0].body,
          postid: docs[0]._id
        });
      });
    } else {
      return res.redirect(303, '/');
    }
  });

  app.get('/comment/:id', function(req, res) {
    var blogposts;
    blogposts = db.get('posts');
    return blogposts.find({
      _id: req.params.id
    }, function(e, docs) {
      return res.render('comment', {
        posttitle: docs[0].title,
        postid: docs[0]._id,
        admin: req.session.admin
      });
    });
  });

  app.post('/comment/:id', function(req, res) {
    var comments, newcomment;
    newcomment = {};
    newcomment.post = req.params.id;
    newcomment.date = new Date();
    newcomment.comment = req.body.comment;
    if (req.body.admin) {
      newcomment.admin = true;
      newcomment.name = username;
    } else {
      newcomment.admin = false;
      newcomment.name = req.body.name;
    }
    comments = db.get('comments');
    comments.insert(newcomment, function(err, doc) {
      if (err) {
        return res.send('Error saving comment.');
      }
    });
    return res.redirect(303, "/post/" + req.params.id);
  });

  app.get('/deletepost/:id', function(req, res) {
    var blogposts, comments;
    if (req.session.admin) {
      blogposts = db.get('posts');
      blogposts.remove({
        _id: req.params.id
      }, function(err, doc) {
        if (err) {
          return res.send('Error deleting post.');
        }
      });
      comments = db.get('comments');
      comments.remove({
        post: req.params.id
      }, function(err, doc) {
        if (err) {
          return res.send('Error deleting comments.');
        }
      });
      return res.redirect(303, '/');
    } else {
      return res.redirect(303, '/');
    }
  });

  app.get('/deletecomment/:post/:comment', function(req, res) {
    var comments;
    if (req.session.admin) {
      comments = db.get('comments');
      comments.remove({
        _id: req.params.comment
      }, function(err, doc) {
        if (err) {
          return res.send('Error deleting comment.');
        }
      });
      return res.redirect(303, '/post/' + req.params.post);
    } else {
      return res.redirect(303, '/post/' + req.params.post);
    }
  });

  app.get('/editcomment/:post/:comment', function(req, res) {
    var comments;
    if (req.session.admin) {
      comments = db.get('comments');
      return comments.find({
        post: req.params.post,
        _id: req.params.comment
      }, function(e, docs) {
        console.log(docs);
        return res.render('editcomment', {
          name: docs[0].name,
          email: docs[0].email,
          comment: docs[0].comment,
          commentid: docs[0]._id,
          postid: req.params.post
        });
      });
    } else {
      return res.redirect(303, '/');
    }
  });

  app.post('/editcomment/:post/:comment', function(req, res) {
    var comments;
    if (req.session.admin) {
      comments = db.get('comments');
      comments.update({
        _id: req.params.comment
      }, {
        $set: {
          'name': req.body.name,
          'email': req.body.email,
          'comment': req.body.comment
        }
      }, function(err, doc) {
        if (err) {
          return res.send('Error editing comment.');
        }
      });
      return res.redirect(303, '/post/' + req.params.post);
    } else {
      return res.redirect(303, '/');
    }
  });

  app.get('/post/:id', function(req, res) {
    var blogposts, comments, commentsColl, complete, post;
    post = null;
    comments = null;
    blogposts = db.get('posts');
    blogposts.find({
      _id: req.params.id
    }, {
      limit: 5,
      sort: {
        date: -1
      }
    }, function(e, docs) {
      post = docs;
      return complete();
    });
    commentsColl = db.get('comments');
    commentsColl.find({
      post: req.params.id
    }, {
      sort: {
        date: 1
      }
    }, function(e, docs) {
      comments = docs;
      return complete();
    });
    return complete = function() {
      if (post !== null && comments !== null) {
        if (isEmptyObject(comments)) {
          comments = false;
        }
        return res.render('post', {
          posttitle: post[0].title,
          postbody: post[0].body,
          postid: post[0]._id,
          postdate: post[0].date.toLocaleDateString(),
          admin: req.session.admin,
          comments: comments
        });
      }
    };
  });

  app.get('/page/:id', function(req, res) {
    var blogposts, complete, nextpage, prevpage, results, totalposts;
    if ((isNaN(req.params.id)) || (req.params.id % 1 !== 0) || (req.params.id < 1)) {
      res.status(404);
      res.render('error.jade', {
        error: '404',
        message: 'The Prosefectionist can write, but he can\'t find your page.'
      });
    }
    results = null;
    totalposts = null;
    prevpage = req.params.id - 1;
    nextpage = null;
    blogposts = db.get('posts');
    blogposts.find({}, {
      limit: pageskip,
      sort: {
        date: -1
      },
      skip: (req.params.id - 1) * pageskip
    }, function(e, docs) {
      results = docs;
      return complete();
    });
    blogposts.count({}, function(e, count) {
      totalposts = count;
      if (count > (req.params.id * pageskip)) {
        nextpage = parseInt(req.params.id) + 1;
      }
      return complete();
    });
    return complete = function() {
      if (results !== null && totalposts !== null) {
        return res.render('page', {
          returnedposts: results,
          title: config.title,
          currpage: req.params.id,
          message: config.message,
          prevpage: prevpage,
          nextpage: nextpage
        });
      }
    };
  });

  isEmptyObject = function(obj) {
    var name;
    name = void 0;
    for (name in obj) {
      return false;
    }
    return true;
  };

  http.createServer(app).listen(config.port, function() {
    return console.log("Express app started on " + config.port);
  });

}).call(this);
