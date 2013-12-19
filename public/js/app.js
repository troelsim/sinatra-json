App = Ember.Application.create();
// Model
App.Company = DS.Model.extend({
	name: DS.attr('string'),
	email: DS.attr('string'),
	city: DS.attr('string'),
	country: DS.attr('string'),
	phone: DS.attr('string'),
	owners: DS.hasMany('owner', {async: true})
});

App.Owner = DS.Model.extend({
	company: DS.belongsTo('company'),
	name: DS.attr('string'),
	passport: DS.attr('string'),
});


App.Router.map(function() {
	this.resource('companies', function(){
		this.route('new');
		this.resource('company', {path: ':company_id'}, function(){
			this.resource('owners', {path: '/owners' },function(){
				this.route('new');
				this.resource('owner', {path: ':owner_id'});
			});
		});
	});
});

App.OwnersNewRoute = Ember.Route.extend({
	setupController: function(controller,params){
		controller.newRecord(params);
	}
});

App.OwnerRoute = Ember.Route.extend({
	model: function() {
		return this.modelFor('order');
	}
});

App.OwnersRoute = Ember.Route.extend({
//	model: function() {
//		return this.modelFor('company').get('owners');
//	}
	model: function() {
		return this.modelFor('company').get('owners');
	}
});

App.CompaniesRoute = Ember.Route.extend({
	model: function() {
		return this.store.find('company');
	}
});

App.CompanyRoute = Ember.Route.extend({
	model: function() {
		return this.store.modelFor('company');
	}
});

App.CompaniesNewRoute = Ember.Route.extend({
	setupController: function(controller){
		controller.newRecord();
	}
});

App.IndexRoute = Ember.Route.extend({
  model: function() {
    return ['red', 'yellow', 'blue'];
  }
});

DS.RESTAdapter.reopen({
  host: 'http://127.0.0.1:9393'
});

// Controllers
App.CompanyController = Ember.ObjectController.extend({
	save: function(){
		var post =  this.get('model');
		post.save();
		console.log(post.get('owners'));
		post.get('owners').forEach(function(owner){
			owner.save();
		});
//		this.get('target.router').transitionTo('companies.index');
	},
	destroyRecord: function(){
		if( window.confirm("Delete company?") ){
			this.get('content').deleteRecord();
			this.get('model').save();
			this.get('target.router').transitionTo('companies.index');
		}
	}
});

App.CompaniesNewController = Ember.ObjectController.extend({
	save: function(){
		this.get('model').save();
		this.get('target.router').transitionTo('companies.index');
	},
	newRecord: function() {
		this.set('content', this.store.createRecord("company"));
	}
});

App.OwnersNewController = Ember.ObjectController.extend({
	needs: "company",
	newRecord: function(params) {
		/*var company = this.controllerFor("company").get('model');
		console.log("company.id:");
		console.log(company.id);
		console.log(company.get('name'));
		var owner = this.store.createRecord('owner', {name: "FUCKNUDIG",company: company});
		//company.get('owners').addObject(owner);
		console.log(company.get('owners'));
		this.store.find('company', company.id).then(function(){
			owner.set('company',company);
		});
		owner.get('company').then(function(){}(
		)
		//console.log(owner.get('company'));*/
		var owner = this.store.createRecord('owner');
		var company = this.controllerFor("company").get('model');
		company.set("owner", company);
		console.log(company.get("owner"));
		company.get("owners").then(function(owners){
			console.log(owners);
			owners.addObject(owner);
		});
		console.log(company.get("owners"));
	}
});

App.OwnersController = Ember.ArrayController.extend({
	companyBinding: 'controller.companyIndex.content',
	needs: ['company']
});
