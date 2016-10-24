$(function(){
	var muranoToken = null;
	var allLocks = [];

	/* render the locks on the screen */
	function render(locks) {
		locks = _.sortBy(locks, ['lockID']);

		var template = $("#lock-template").html();
		var compiledTemplate = _.template(template);
		$('#locks').html(compiledTemplate({locks: locks}));

		// connect button events
		$('.button-lock').click(function() {
			lockCommand($(this).data("id"), 'locked');
		});
		$('.button-unlock').click(function() {
			lockCommand($(this).data("id"), 'unlocked');
		});
	}

	/* sign in by posting to /token to get a token and setting 
     it in muranoToken */
	function signIn() {
		console.log('signing in...');
    $.ajax({
      method: 'POST',
      url: '/token',
      data: JSON.stringify({email: $('#email').val(), password: $('#password').val()}),
      headers: {
        'Content-Type': 'application/json'
      },
      success: function(data) {
				muranoToken = data.token;
				$('#nav-signedin-message').html('Signed in as <b>' + data.name + '</b> ');
				$('.nav-signedout').hide();
				$('.nav-signedin').show();

				// get locks based on 
				getLocks();
     },
      error: function(xhr, textStatus, errorThrown) {
        alert(errorThrown);
      }
		});

	}

	/* sign out by setting muranoToken to null */
	function signOut() {
		muranoToken = null;
		$('#email').val('');
		$('#password').val('');
		$('.nav-signedout').show();
		$('.nav-signedin').hide();
	}

	/* Update the locks with a particular message
     e.g. one received over a websocket. */
	function updateLocks(message) {
		// message looks like:
		// {"battery-percent":"1","lockID":"001"}
		if (!_.has(message, 'lockID')) {
			// this may be the initial {"status":"ok"} message
			return;
		}
		var lockID = message.lockID;
		// remove lockID
		message = _.omit(message, ['lockID']);
		// update the state with the rest of the message
		_.each(allLocks, function(lock) {
			if (lock.lockID === lockID) {
				_.assign(lock.state, message);
			}
		});
	}

	/* Get all of the locks, using the authentication-free
     endpoint if no token is set, otherwise then authenticated
		 endpoint. */
	function getLocks() {
		var params = {
			method: 'GET',
			url: '/lock/',
			success: function(data) {
				allLocks = data;	
				render(allLocks);
			},
			error: function(xhr, textStatus, errorThrown) {
				alert(errorThrown)
			}
		};
		// we're signed in.
		if (muranoToken) {
			// include the token as a header
			// note that this is not strictly necessary
			// since the API will have put it in the cookie, 
			// but a native mobile app would have to do this.
			params.headers = {
				'token': muranoToken
			};
			// call the user-specific lock listing.
			params.url = '/user/lock/';
		}
		$.ajax(params);
	}
	/* send a command to the lock. 
     state may be 'locked' or 'unlocked' */
  function lockCommand(sn, state) {
    $.ajax({
      method: 'POST',
      url: '/lock/' + sn,
      data: '{"lock-command":"' + state + '"}',
      headers: {
        'Content-Type': 'application/json'
      },
      success: function() {
				getLocks();
      },
      error: function(xhr, textStatus, errorThrown) {
        alert(errorThrown);
      }
    });
  }

	var socket;
	function initWebsocket() {
		socket = new WebSocket("wss://" + location.host + "/notify");
		socket.onmessage = function (event) {
			var message = JSON.parse(event.data);
			updateLocks(message);
			render(allLocks);
		}
	}

	// update state
	getLocks();
	
	// set initial state of signin controls
	$('.nav-signedin').hide();

	// support frank and judy login buttons
	$('#login-frank').click(function() {
		$('#email').val('frank@exosite.com');
		$('#password').val('frank-password1');
	});
	$('#login-judy').click(function() {
		$('#email').val('judy@exosite.com');
		$('#password').val('judy-password1');
	});
	$('#sign-in').click(function() {
		signIn();
	});
	$('#sign-out').click(function() {
		signOut();
	});

	// start listening for notifications on the websocket
	initWebsocket();

});
