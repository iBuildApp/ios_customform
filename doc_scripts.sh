headerdoc2html -j -o mCustomForm/Documentation mCustomForm/mCustomForm.h
headerdoc2html -j -o mCustomForm/Documentation mCustomForm/MIRadioButtonGroup.h


gatherheaderdoc mCustomForm/Documentation


sed -i.bak 's/<html><body>//g' mCustomForm/Documentation/masterTOC.html
sed -i.bak 's|<\/body><\/html>||g' mCustomForm/Documentation/masterTOC.html
sed -i.bak 's|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">||g' mCustomForm/Documentation/masterTOC.html