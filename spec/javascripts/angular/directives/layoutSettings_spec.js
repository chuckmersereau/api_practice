describe('layoutSettings Directive', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function(_layoutSettings_, _$compile_, _$rootScope_) {
        self.layoutSettings = _layoutSettings_;
        self.$compile = _$compile_;
        self.$rootScope = _$rootScope_;
    }));

    describe('fullPage', function() {
        it('should make default value available to template', function(){
            var element = self.$compile("<div layout-settings>{{$ctrl.layoutSettings.fullWidth}}</div>")(self.$rootScope);
            self.$rootScope.$digest();
            expect(element.html()).toEqual('false');
        });

        it('should update value available to template when layoutSettings changes', function(){
            var element = self.$compile("<div layout-settings>{{$ctrl.layoutSettings.fullWidth}}</div>")(self.$rootScope);
            self.$rootScope.$digest();
            expect(element.html()).toEqual('false');
            self.layoutSettings.fullWidth = true;
            self.$rootScope.$digest();
            expect(element.html()).toEqual('true');
        });
    });
});
