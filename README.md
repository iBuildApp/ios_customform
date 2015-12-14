Use our code to save yourself time on cross-platform, cross-device and cross OS version development and testing
# ios_module_CustomForm
Custom Form widget is intended for construction and displaying of a form for filling information and sending it's result by eMail.

Management elements: text area, entry field, checkbox, radio button, dropdown list, datapicker - can be divided by groups.

Tags:

- title - widget name. Title is being displayed on navigation panel when widget is launched.
- colorskin - this is root tag to set up color scheme. Contains 5 elements (color[1-5]). Each widget may set colors for elements of the interface using the color scheme in any order, however generally color1 - background color, color3 - titles color, color4 - font color, color5 - date or price color.
- form - root tag for information of management elements.
 - email - root tag for configuration of email address being used for sending result;
  - address - address for sending email;
  - subject - email subject;
  - button - root tag for parameters of a button which opens email form for sending result
 - label - button title
- group - root tag for a group of elements
 - title - group name (title)
 - entryfield - root tag for entry field element. Contains "format" attribute, which can be set up with number (number input) and general (text) values. Tags: label and value - declares element title and value by default.
 - textarea - root tag for text area element, is intended for multipline text input. Tags: label and value - declares element title and value by default.
 - checkbox - root tag for checkbox element. Tags: label and value - declares element title and value by default.
 - radiobutton - root tag for radio button element. Tags: label and value - declares element title and value by default.
 - dropdown - root tag for dropdown list element. Tag title declares title of the element, set of "value" tags declares array of possible values.
 - datepicker - root tag for datepicker element. Tags: label and value - declares element title and value by default.
 - photopicker - root tag for photopicker element, intended for attaching images to email 
