//utilities.js

//Confirm deletion of posts
deletePost = function() {
	if (confirm("Delete this post?")) {
		return true;
	}
	return false;
};

if (document.getElementById("deletepost")) {
	document.getElementById("deletepost").onclick = deletePost;
}


//Confirm deletion of comments
var deletecomment = document.getElementsByClassName("deletecomment")

for (var i = 0; i < deletecomment.length; i++) {
	deletecomment[i].onclick = function() {
		if (confirm("Delete this comment?")) {
			return true;
		}
		return false;
	};
};

