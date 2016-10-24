$(function(){
	var muranoToken = null;

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
				console.log('Signed in. Token is ', muranoToken);
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

	/* Get all of the locks using the authentication-free
     endpoint. */
	function getLocks(sn, state) {
		var params = {
			method: 'GET',
			url: '/lock/',
			success: function(locks) {
				console.log('getLocks:', locks);
				render(locks);
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

});
