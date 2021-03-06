Meteor.publish 'roomSearch', (selector, options, collName) ->
	unless this.userId
		return this.ready()

	console.log '[publish] roomSearch -> '.green, 'selector:', selector, 'options:', options, 'collName:', collName

	self = this
	searchType = null
	subHandleUsers = null
	subHandleRooms = null

	if selector.type
		searchType = selector.type
		delete selector.type

	if not searchType? or searchType is 'u'
		subHandleUsers = Meteor.users.find(selector, { limit: 10, fields: { name: 1, username: 1, status: 1 } }).observeChanges
			added: (id, fields) ->
				data = { type: 'u', uid: id, name: fields.name, username: fields.username, status: fields.status }
				self.added("autocompleteRecords", id, data)
			changed: (id, fields) ->
				self.changed("autocompleteRecords", id, fields)
			removed: (id) ->
				self.removed("autocompleteRecords", id)

	if not searchType? or searchType is 'r'
		roomSelector = _.extend { t: { $in: ['c','p'] }, usernames: Meteor.users.findOne(this.userId).username }, selector
		subHandleRooms = ChatRoom.find(roomSelector, { limit: 10, fields: { t: 1, name: 1 } }).observeChanges
			added: (id, fields) ->
				data = { type: 'r', rid: id, name: fields.name, t: fields.t }
				self.added("autocompleteRecords", id, data)
			changed: (id, fields) ->
				self.changed("autocompleteRecords", id, fields)
			removed: (id) ->
				self.removed("autocompleteRecords", id)

	this.ready()

	this.onStop ->
		subHandleUsers?.stop()
		subHandleRooms?.stop()
