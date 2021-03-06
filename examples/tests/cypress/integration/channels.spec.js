describe('Channels', () => {
  ['sse', 'ws'].forEach(type => {
    it(`Creates ${type} subscription, sends & receives public events`, () => {
      cy.visit('http://localhost:3000');
      cy.connect(type);
      cy.subscribe('mike', 'my.public.event');
      // "foo":"bar" due to way how Cypress handles escaping of curly braces
      cy.sendEvent('my.public.event', '"foo":"bar"');
      cy.assertReceivedEvents('event-log', '(.*my.public.event)(.*"foo":"bar")');
      cy.disconnect();
    });

    it(`Creates ${type} subscription, sends & receives private (constrained) events`, () => {
      cy.visit('http://localhost:3000');
      cy.connect(type);
      cy.subscribe('mike', 'message');
      // "name":"mike","foo":"bar" due to way how Cypress handles escaping of curly braces
      cy.sendEvent('message', '"name":"mike","foo":"bar"');
      cy.assertReceivedEvents('event-log', 'message', '"name":"mike","foo":"bar"');
      // send constrained event for different user - John
      cy.sendEvent('message', '"name":"john","foo":"bar"');
      // Mike shouldn't receive any new event
      cy.wait(2000).assertReceivedEvents(
        'event-log',
        '(.*message)(.*"name":"mike","foo":"bar")'
      );
      cy.disconnect();
    });
  });
});
