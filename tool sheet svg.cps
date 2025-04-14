/**
  Copyright (C) 2025 by Ken
  Copyright (C) 2012-2021 by Autodesk, Inc.

  Tool Sheet (HTML/SVG)

  Uses SVGs for tools, HTML for overall document.

  The stock tool sheet post includes a lot of fields that aren't relevant to
  loading tools into the machine. Its formatted such that it creates a lot of
  blank space, so it becomes many pages, or scaling it down to get some
  balance.

  This post focuses on only the most relevant information. Organized in a way
  to make the most use of the space. A normal page should fit 12 tools with
  normal margins and scale settings. If you have duplex printing, you can fit
  24 tools on a single sheet.
*/

description = "Tool Sheet (HTML/SVG)";
vendor = "RCC";
vendorUrl = "https://github.com/krobertson/fusion-360-post-processors";
certificationLevel = 2;

longDescription = "Setup sheet intended for presenting all tools used in SVG.";

capabilities = CAPABILITY_SETUP_SHEET;
extension = "html";
mimetype = "text/html";
setCodePage("utf-8");

allowMachineChangeOnSection = true;

properties = {
  showRadius: {
    title      : "Show radius values",
    description: "Enables showing tool as radius, useful for Heidenhain.",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useUnitSymbol: {
    title      : "Use unit symbol",
    description: "Specifies that symbols should be used for units (some printers may not support this).",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  showToolImage: {
    title      : "Show tool images",
    description: "If enabled, tool images will be included in the seutp sheet.",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  toolAsName: {
    title      : "Output tool as name",
    description: "Specifies whether to output the tool as a name instead of a number.",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  embedImages: {
    title      : "Embed images",
    description: "If enabled, images are embedded into the HTML file.",
    type       : "boolean",
    value      : true,
    scope      : "post"
  }
};

var useToolNumber = true;

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 5)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3});
var angleFormat = createFormat({decimals:0, scale:DEG});
var pitchFormat = createFormat({decimals:3});

// presentation formats
var spatialFormat = createFormat({decimals:3});
var percentageFormat = createFormat({decimals:1, forceDecimal:true, scale:100});
var timeFormat = createFormat({decimals:2});
var taperFormat = angleFormat; // share format

function getUnitSymbolAsString() {
  switch (unit) {
  case MM:
    return getProperty("useUnitSymbol") ? "&#x339c;" : "mm";
  case IN:
    return getProperty("useUnitSymbol") ? "&#x2233;" : "in";
  default:
    error(localize("Unit is not supported."));
    return undefined;
  }
}

/** Returns the given spatial value in MM. */
function toMM(value) {
  return value * ((unit == IN) ? 25.4 : 1);
}

/** Returns the SVG representation of the given tool. */
function getToolAsSVG(tool) {
  var fragment = "";

  var pageWidth = 25;
  var pageHeight = 30;

  var box = tool.getExtent(true);

  var width = box.upper.x - box.lower.x;
  var height = box.upper.y - box.lower.y;
  var dx = toMM(width);
  var dy = toMM(height);
  var dimension = Math.min(width, height);
  var margin = toPreciseUnit(1, MM);
  var backgroundColor = "#ffffff";

  fragment += "<svg class=\"toolimage\" x=\"71\" y=\"6\" width=\"" + xyzFormat.format(pageWidth) + "\" height=\"" + xyzFormat.format(pageHeight) + "\" viewBox=\"" + xyzFormat.format(box.lower.x - margin) + " " + xyzFormat.format(box.lower.y - margin) + " " + xyzFormat.format(width + 2 * margin) + " " + xyzFormat.format(height + 2 * margin) + "\" style=\"background:" + backgroundColor + "\"" + ">";

  fragment += "<defs>";
  fragment += "<linearGradient id='holderGrad' x1='0%' y1='0%' x2='100%' y2='0%'>";
  fragment += "<stop offset='0%' style='stop-color:rgb(120,120,120);stop-opacity:1'/>";
  fragment += "<stop offset='50%' style='stop-color:rgb(180,180,180);stop-opacity:0.5'/>";
  fragment += "<stop offset='100%' style='stop-color:rgb(150,150,150);stop-opacity:1'/>";
  fragment += "</linearGradient>";
  if (!tool.isJetTool()) { // we only show cutting head
    fragment += "<linearGradient id='cutterGrad' x1='0%' y1='0%' x2='100%' y2='0%'>";
    fragment += "<stop offset='0%' style='stop-color:rgb(228,175,52);stop-opacity:1'/>";
    fragment += "<stop offset='50%' style='stop-color:rgb(240,240,240);stop-opacity:1'/>";
    fragment += "<stop offset='100%' style='stop-color:rgb(228,175,52);stop-opacity:1'/>";
    fragment += "</linearGradient>";
  }
  fragment += "</defs>";

  if (!tool.isTurningTool()) {
    // invert y axis
    fragment += "<g transform=\"translate(" + xyzFormat.format(0) + ", " + xyzFormat.format(height) + ")\">";
    fragment += "<g transform=\"scale(1, -1)\">";
  }

  var holder = tool.getHolderProfileAsSVGPath();
  if (holder) {
    fragment += "<path class=\"holder\" d=\"" + holder + "\" style=\"fill:url(#holderGrad);vector-effect:non-scaling-stroke;stroke:black;stroke-opacity:0.9\"/>";
  }

  var cutter = !tool.isJetTool() ? tool.getCutterProfileAsSVGPath() : undefined;
  if (cutter) {
    // indicate if insert is on the other side stroke-dasharray=\"3px,3px\"
    fragment += "<path class=\"cutter\" d=\"" + cutter + "\" style=\"fill:url(#cutterGrad);vector-effect:non-scaling-stroke;stroke:black;fill-opacity:1.0;stroke-opacity:0.9\"/>";
  }

  if (false && tool.isTurningTool()) { // mark the compensation point
    var offset = tool.getCompensationDisplacement();
    fragment += "<circle cx=\"" + xyzFormat.format(offset.x) + "\" cy=\"" + xyzFormat.format(offset.y) + "\" r=\"" + "2.5px" + "\" style=\"fill:red;fill-opacity:0.5;vector-effect:non-scaling-stroke\"/>";
  }

  if (!tool.isTurningTool()) {
    fragment += "</g>";
    fragment += "</g>";
  }
  fragment += "</svg>";
  return fragment;
}

function onSection() {
  if (getProperty("toolAsName") && !tool.description) {
    if (hasParameter("operation-comment")) {
      error(localize("Tool description is empty in operation " + "\"" + (getParameter("operation-comment").toUpperCase()) + "\""));
    } else {
      error(localize("Tool description is empty."));
    }
    return;
  }
  skipRemainingSection();
}

function onClose() {
  write(
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n" +
    "                      \"http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd\">\n"
  );
  write("<html>");

  // header
  write("<head>");
  write(
    "<style type=\"text/css\">\n" +
    "  h1 {\n" +
    "    font-family: Inter, system-ui, sans-serif;\n" +
    "    font-size: 20px;\n" +
    "    text-align: center;\n" +
    "    margin: 5px 5px 5px 5px;\n" +
    "  }\n" +
    "  td.tool {\n" +
    "    padding: 5px 5px 5px 5px;\n" +
    "  }\n" +
    "  text {\n" +
    "    fill: black;\n" +
    "    font-family: Inter, system-ui, sans-serif;\n" +
    "    font-size: 2.5px;\n" +
    "    font-weight: bold;\n" +
    "    -webkit-font-smoothing: antialiased;\n" +
    "    -moz-osx-font-smoothing: grayscale;\n" +
    "    text-anchor: start;\n" +
    "    alignment-baseline: bottom;\n" +
    "  }\n" +
    "  text.h1 {\n" +
    "    text-anchor: middle;\n" +
    "    font-size: 5px;\n" +
    "  }\n" +
    "  text.h2 {\n" +
    "    font-size: 3px;\n" +
    "  }\n" +
    "  text.h3 {\n" +
    "    font-size: 2.5px;\n" +
    "  }\n" +
    "  text.h4 {\n" +
    "    text-anchor: end;\n" +
    "    font-size: 2.5px;\n" +
    "    font-weight: normal;\n" +
    "  }\n" +
    "  rect.toolBorder {\n" +
    "    fill:none;\n" +
    "    stroke:#000000;\n" +
    "    stroke-width:0.25;\n" +
    "    stroke-opacity:0.33;\n" +
    "  }\n" +
    "</style>\n"
  );
  write("</head>");

  write("<body>");
  write("<table>");
  write("<tr><td colspan=\"2\"><h1>" + getParameter("document-path") + "</h1></td></tr>\n")

  // parameters for boxes
  width = 96.96;
  height = 39;

  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);

      if (i % 2 == 0) {
        write("<tr>");
      }

      write(
        "<td class=\"tool\">\n" +
        "<svg\n" +
        "  viewBox=\"0 0 " + width + " " + height + "\"\n" +
        "  width=\"" + width + "mm\"\n" +
        "  height=\"" + height + "mm\">\n"
      );

      write(
        "<rect\n" +
        "  class=\"toolBorder\"\n" +
        "  width=\"" + (width-0.5) + "\"\n" +
        "  height=\"" + (height-0.5) + "\"\n" +
        "  rx=\"1\" ry=\"1\"\n" +
        "  x=\"0.25\"\n" +
        "  y=\"0.25\" />\n"
      );


      if (getProperty("toolAsName")) {
        write("<text class=\"h2\" x=\"2\" y=\"4\">"+ localize("Tool") + ":" + tool.description + "</text>\n");
      } else {
        write("<text class=\"h2\" x=\"2\" y=\"4\">"+ localize("Tool") + " #" + toolFormat.format(tool.number) + " (" + tool.description + ")</text>\n");
      }

      // full width info
      write("<text class=\"h4\" x=\"14\" y=\"9\">Type:</text>\n");
      write("<text class=\"h3\" x=\"15\" y=\"9\">" + getToolTypeName(tool.type) + "</text>\n");
      space = 13;
      if (tool.vendor || tool.productId) {
        write("<text class=\"h4\" x=\"14\" y=\"" + space + "\">Vendor:</text>\n");
        write("<text class=\"h3\" x=\"15\" y=\"" + space + "\">" + (tool.vendor ? tool.vendor : "") + " " + (tool.productId ? tool.productId : "" ) + "</text>\n");
        space += 4;
      }
      if (tool.holderDescription) {
        write("<text class=\"h4\" x=\"14\" y=\"" + space + "\">Holder:</text>\n");
        write("<text class=\"h3\" x=\"15\" y=\"" + space + "\">" + tool.holderDescription + "</text>\n");
      }

      // left column
      if (!getProperty("showRadius")) {
        write("<text class=\"h4\" x=\"21\" y=\"25\">Diameter:</text>\n");
        write("<text class=\"h3\" x=\"22\" y=\"25\">" + spatialFormat.format(tool.diameter) + getUnitSymbolAsString() + "</text>\n");
      } else {
        write("<text class=\"h4\" x=\"21\" y=\"25\">Radius:</text>\n");
        write("<text class=\"h3\" x=\"22\" y=\"25\">" + spatialFormat.format(tool.diameter/2) + getUnitSymbolAsString() + "</text>\n");
      }
      write("<text class=\"h4\" x=\"21\" y=\"29\">Flutes:</text>\n");
      write("<text class=\"h3\" x=\"22\" y=\"29\">" + tool.numberOfFlutes + "</text>\n");
      if (tool.cornerRadius) {
        write("<text class=\"h4\" x=\"21\" y=\"33\">CR:</text>\n");
        write("<text class=\"h3\" x=\"22\" y=\"33\">" + spatialFormat.format(tool.cornerRadius) + getUnitSymbolAsString() + "</text>\n");
      }
      if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI)) {
        if (tool.isDrill()) {
          write("<text class=\"h4\" x=\"21\" y=\"33\">Tip Angle:</text>\n");
          write("<text class=\"h3\" x=\"22\" y=\"33\">" + taperFormat.format(tool.taperAngle) + "</text>\n");
        } else {
          write("<text class=\"h4\" x=\"21\" y=\"33\">Taper Angle:</text>\n");
          write("<text class=\"h3\" x=\"22\" y=\"33\">" + taperFormat.format(tool.taperAngle) + "</text>\n");
        }
      }

      // right column
      write("<text class=\"h4\" x=\"51\" y=\"25\">LOC:</text>\n");
      write("<text class=\"h3\" x=\"52\" y=\"25\">" + spatialFormat.format(tool.fluteLength) + getUnitSymbolAsString() + "</text>\n");
      write("<text class=\"h4\" x=\"51\" y=\"29\">LBH:</text>\n");
      write("<text class=\"h3\" x=\"52\" y=\"29\">" + spatialFormat.format(tool.bodyLength) + getUnitSymbolAsString() + "</text>\n");

      // image
      if (getProperty("showToolImage")) {
        // box around tool image
        // write(
        //   "<rect\n" +
        //   "  style=\"fill:none;stroke:#000000;stroke-width:0.25;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.33;paint-order:markers stroke fill\"\n" +
        //   "  width=\"25\"\n" +
        //   "  height=\"30\"\n" +
        //   "  x=\"71\"\n" +
        //   "  y=\"6\" />\n"
        // );

        write(getToolAsSVG(tool));
      }

      write("</svg></td>\n");
      if (i % 2 == 1) {
        write("</tr>\n");
      }
      writeln("");
      writeln("");
    }
  }

  // write closing tr if odd number of tools
  if (tools.getNumberOfTools() % 2 == 1) {
    write("</tr>\n");
  }

  write(
    "</table>\n" +
    "</body>\n" +
    "</html>\n"
  );
}

function onComment(text) {
}

function quote(text) {
  var result = "";
  for (var i = 0; i < text.length; ++i) {
    var ch = text.charAt(i);
    switch (ch) {
    case "\\":
    case "\"":
      result += "\\";
    }
    result += ch;
  }
  return "\"" + result + "\"";
}

function onTerminate() {
  // add this to print automatically - you could print to XPS and PDF writer
  /*
  var device = "Microsoft XPS Document Writer";
  if (device) {
    executeNoWait("rundll32.exe", "mshtml.dll,PrintHTML " + quote(getOutputPath()) + quote(device), false, "");
  } else {
    executeNoWait("rundll32.exe", "mshtml.dll,PrintHTML " + quote(getOutputPath()), false, "");
  }
  */
}
