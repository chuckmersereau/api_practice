describe('api service', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function(api, $httpBackend) {
        self.api = api;
        self.$httpBackend = $httpBackend;
    }));

    afterEach(function() {
        self.$httpBackend.verifyNoOutstandingExpectation();
        self.$httpBackend.verifyNoOutstandingRequest();
    });

    describe('call', function(){
        describe('promise', function(){
            it('should send a simple get request', function(){
                self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                self.api.call('get', 'contacts', {}, null, null, false)
                    .then(function(data){
                        expect(data).toEqual('Success');
                    }, function(){
                        fail('should have returned Success');
                    });
                self.$httpBackend.flush();
            });
            it('should handle an error in a get request', function(){
                self.$httpBackend.expectGET('/api/v1/contacts').respond(500, 'Error');

                self.api.call('get', 'contacts', {}, null, null, false)
                    .then(function(){
                        fail('should have returned an error');
                    }, function(response){
                        expect(response.data).toEqual('Error');
                    });
                self.$httpBackend.flush();
            });

            describe('cache', function(){
                it('should make a XHR request since it is not cached', function(){
                    self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                    self.api.call('get', 'contacts', {}, null, null, true)
                        .then(function(data){
                            expect(data).toEqual('Success');
                        }, function(){
                            fail('should have returned Success');
                        });
                    self.$httpBackend.flush();
                });

                it('should make not make an XHR request the second time', function(){
                    self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                    function runApiCall(){
                        self.api.call('get', 'contacts', {}, null, null, true)
                            .then(function(data){
                                expect(data).toEqual('Success');
                            }, function(){
                                fail('should have returned Success');
                            });
                    }

                    runApiCall();
                    self.$httpBackend.flush();
                    runApiCall();
                });
            });
        });
        describe('callback', function(){
            it('should send a simple get request', function(){
                self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                self.api.call('get', 'contacts', {}, function(data){
                    expect(data).toEqual('Success');
                }, function(){
                    fail('should have returned Success');
                }, false);

                self.$httpBackend.flush();
            });
            it('should handle an error in a get request', function(){
                self.$httpBackend.expectGET('/api/v1/contacts').respond(500, 'Error');

                self.api.call('get', 'contacts', {}, function(){
                    fail('should have returned an error');
                }, function(response){
                    expect(response.data).toEqual('Error');
                }, false);

                self.$httpBackend.flush();
            });

            describe('cache', function(){
                it('should make a XHR request since it is not cached', function(){
                    self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                    self.api.call('get', 'contacts', {}, function(data){
                        expect(data).toEqual('Success');
                    }, function(){
                        fail('should have returned Success');
                    }, true);
                    self.$httpBackend.flush();
                });

                it('should make not make an XHR request the second time', function(){
                    self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

                    function runApiCall(){
                        self.api.call('get', 'contacts', {}, function(data){
                            expect(data).toEqual('Success');
                        }, function(){
                            fail('should have returned Success');
                        }, true);
                    }

                    runApiCall();
                    self.$httpBackend.flush();
                    runApiCall();
                });
            });
        });
    });

    describe('get', function(){
        it('should send a simple get request', function(){
            self.$httpBackend.expectGET('/api/v1/contacts').respond(200, 'Success');

            self.api.get('contacts', {}, null, null, false)
                .then(function(data){
                    expect(data).toEqual('Success');
                }, function(){
                    fail('should have returned Success');
                });
            self.$httpBackend.flush();
        });
    });

    describe('post', function(){
        it('should send a simple post request', function(){
            self.$httpBackend.expectPOST('/api/v1/contacts').respond(200, 'Success');

            self.api.post('contacts', {}, null, null, false)
                .then(function(data){
                    expect(data).toEqual('Success');
                }, function(){
                    fail('should have returned Success');
                });
            self.$httpBackend.flush();
        });
    });

    describe('encodeURLarray', function(){
        it('should encode an array of values', function(){
            expect(self.api.encodeURLarray(['handles spaces', '?&'])).toEqual([ 'handles%20spaces', '%3F%26' ]);
        });
    });
});
