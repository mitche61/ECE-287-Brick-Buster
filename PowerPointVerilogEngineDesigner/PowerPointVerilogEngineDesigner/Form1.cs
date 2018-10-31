﻿using GemBox.Presentation;
using Microsoft.VisualBasic;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace PowerPointVerilogEngineDesigner
{
    public partial class Form1 : Form
    {
        PresentationDocument mainDocument;
        List<PresentationDocument> referenceDocuments = new List<PresentationDocument>();

        string currentProjectFilePath = "";
        string currentProjectFolderPath = "";

        FileSystemWatcher watcher = new FileSystemWatcher();

        public Form1()
        {
            InitializeComponent();
            Console.SetOut(new MultiTextWriter(new ControlWriter(textBoxOutput), Console.Out));
            ComponentInfo.SetLicense("FREE-LIMITED-KEY");
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (checkBoxClearLog.Checked) textBoxOutput.Clear();

            Task.Run(() => {
                Stopwatch watch = new Stopwatch();
                watch.Start();
                Console.WriteLine("Loading PowerPoint document main.pptx...");
                mainDocument = PresentationDocument.Load(currentProjectFolderPath + "\\PPVerilogEngine\\main.pptx");
                Console.WriteLine("Loaded PowerPoint document main.pptx!");

                using (StreamWriter writer = new StreamWriter(currentProjectFolderPath + "\\IH8Verilog_main.v"))
                {
                    Console.WriteLine("Writing main module definition...");
                    writer.WriteLine("module PP2VerilogDrawingController(xPixel,yPixel,VGAr,VGAg,VGAb,mouseX,mouseY);" + Environment.NewLine);

                    writer.WriteLine("input [9:0]xPixel;" + Environment.NewLine + "input[8:0]yPixel;");
                    writer.WriteLine("input [10:0]mouseX;");
                    writer.WriteLine("input [10:0]mouseY;");
                    writer.WriteLine("output [7:0]VGAr;");
                    writer.WriteLine("output [7:0]VGAg;");
                    writer.WriteLine("output [7:0]VGAb;");
                    writer.WriteLine("reg [7:0]VGAr;");
                    writer.WriteLine("reg [7:0]VGAg;");
                    writer.WriteLine("reg [7:0]VGAb;");
                    writer.WriteLine();

                    writer.WriteLine("always @(*)");
                    writer.WriteLine("begin\n");

                    Console.WriteLine("Compiling and writing first slide...");
                    if (mainDocument.Slides.Count > 0) writeSlide(mainDocument.Slides[0], 1, writer);

                    //GemBox.Presentation.Color color = GemBox.Presentation.Color.FromRgb(255, 255, 255);

                   // writeMouse(writer, color, 1, new Size(20, 20));

                    writer.WriteLine("\nend");

                    writer.WriteLine(Environment.NewLine + "endmodule");



                    watch.Stop();
                    Console.WriteLine("Compilation finished. Took {0}s.",watch.ElapsedMilliseconds/1000.0f);

                }

             

            });
            
        }

        void writeSlide(Slide slide,int tabs,StreamWriter writer)
        {
            Console.WriteLine(getTabs(1) + "Reading properties from slide:");
            Dictionary<string, string> slideProperties=new Dictionary<string, string>();
            if(slide.Notes!=null)
            {
                slideProperties=getProperties(slide.Notes.Content.Drawings.OfType<Shape>().Single(sp => sp.Placeholder.PlaceholderType == PlaceholderType.Text).Text);                
            }

            for(int i=0;i<slideProperties.Values.Count;i++)
            {
                Console.WriteLine(getTabs(2) + slideProperties.Keys.ElementAt(i) + " = " + slideProperties.Values.ElementAt(i));
            }

            //Background color
            System.Drawing.Color backColor = System.Drawing.Color.White;  
            if (slideProperties.ContainsKey("BACKCOLOR"))
            {
                backColor = parseColor(slideProperties["BACKCOLOR"]);                
            }
            

            writer.WriteLine(getTabs(tabs)+"//Writing backgound color");
            writer.WriteLine(getTabs(tabs)+"VGAr = " + formatNumber("b", 8, Convert.ToString(backColor.R, 2).PadLeft(8, '0')) + ";");
            writer.WriteLine(getTabs(tabs)+"VGAg = " + formatNumber("b", 8, Convert.ToString(backColor.G, 2).PadLeft(8, '0')) + "; ");
            writer.WriteLine(getTabs(tabs)+"VGAb = " + formatNumber("b", 8, Convert.ToString(backColor.B, 2).PadLeft(8, '0')) + "; ");

            Console.WriteLine(getTabs(1) + "Writing basic shapes...");
            drawBasicShapes(writer, mainDocument.Slides[0],tabs);

            Console.WriteLine(getTabs(1) + "Writing pictures...");
            drawBasicPictures(writer,mainDocument.Slides[0],tabs);
        }

        private void drawBasicPictures(StreamWriter writer, Slide slide, int tabs)
        {
            //Draw pictures
            foreach (Picture picture in slide.Content.Drawings.OfType<Picture>())
            {
                if (picture.DrawingType == DrawingType.Picture)
                {
                    Dictionary<string, string> properties = getProperties(null, picture.AlternativeText.Description);

                    Console.WriteLine(getTabs(2) + "Writing picture: " + (properties.ContainsKey("NAME") ? properties["NAME"] : (properties.ContainsKey("CURSOR") ? "Mouse" : "UNNAMED")));
                  
                    int compresionFactor = 1;
                    int maxColorBits = 8;
                    if (properties.ContainsKey("COMPRESIONLEVEL")) compresionFactor = int.Parse(properties["COMPRESIONLEVEL"]);
                    if (properties.ContainsKey("COLORBITS")) maxColorBits = int.Parse(properties["COLORBITS"]);
                    Bitmap baseBitmap = new Bitmap(picture.Fill.Data.Content.Open());
                    if (Directory.Exists(currentProjectFolderPath + "/PPVerilogEngine//tempPictures") == false) Directory.CreateDirectory(currentProjectFolderPath + "/PPVerilogEngine//tempPictures");
                    baseBitmap.Save(currentProjectFolderPath + "/PPVerilogEngine//tempPictures//basePicture.png");
                    DrawingLayout finalLayout = getScaledLayout(picture.Layout);

                    if(properties.ContainsKey("CURSOR"))
                    {
                        Size size = new Size(10, 10);
                        if (properties.ContainsKey("CURSOR-SIZE")) size = new Size(int.Parse(properties["CURSOR-SIZE"].Split(',')[0]), int.Parse(properties["CURSOR-SIZE"].Split(',')[1]));

                        Bitmap resizedBitmap = new Bitmap(baseBitmap,size);
                        resizedBitmap.Save(currentProjectFolderPath + "/PPVerilogEngine//tempPictures//compressedPicture.png");

                        Bitmap colorSetBitmap = new Bitmap(resizedBitmap);
                        colorSetBitmap = limitColorBitmap(colorSetBitmap, maxColorBits);
                        colorSetBitmap.Save(currentProjectFolderPath + "/PPVerilogEngine//tempPictures//colorLimitedPicture.png");

                        int savedPixels = 0;
                        int usedPixels = 0;
                        writer.WriteLine(Environment.NewLine + getTabs(tabs) + "//Drawing mouse: ");
                        for (int i = 0; i < colorSetBitmap.Height; i++)
                        {
                            int startingPixel = -1;
                            var startingColor = System.Drawing.Color.White;
                            for (int j = 0; j < colorSetBitmap.Width; j++)
                            {
                                System.Drawing.Color color = colorSetBitmap.GetPixel(j, i);
                                if (color.A > 100)
                                {
                                    if (startingPixel == -1)
                                    {
                                        startingPixel = j;
                                        startingColor = color;
                                    }
                                    else
                                    {
                                        if ((color.R != startingColor.R || color.G != startingColor.G || color.B != startingColor.B) || j == colorSetBitmap.Width - 1) //Not the same, write the old one  || From startingPixel to current-1 in width (j)
                                        {
                                            writer.Write(getTabs(tabs) + "if(yPixel>=(mouseY+" + (int)((i * compresionFactor)) + ") && yPixel<(mouseY+" + (int)(((i + 1) * compresionFactor)) + ") && xPixel>=(mouseX+" + (int)((startingPixel * compresionFactor)) + ") && xPixel<(mouseX+" + (int)((j * compresionFactor)) + ")) ");

                                            writer.WriteLine("{VGAr,VGAg,VGAb}={" + formatNumber("b", 8, Convert.ToString(startingColor.R, 2).PadLeft(8, '0')) + "," + formatNumber("b", 8, Convert.ToString(startingColor.G, 2).PadLeft(8, '0')) + "," + formatNumber("b", 8, Convert.ToString(startingColor.B, 2).PadLeft(8, '0')) + "};");

                                            startingColor = color;
                                            startingPixel = j;
                                            usedPixels++;
                                        }
                                        else
                                        {
                                            savedPixels++;
                                            //Do nothing, is still the same color, keep waiting until it changes.
                                        }
                                    }
                                }
                            }
                        }

                        Console.WriteLine(getTabs(3) + "Mouse drawn at " + Math.Round((float)usedPixels / (baseBitmap.Width * baseBitmap.Height) * 100, 2) + "% of the original size!");

                    }
                    else
                    {
                        Bitmap resizedBitmap = new Bitmap(baseBitmap, new Size((int)(finalLayout.Width / compresionFactor), (int)(finalLayout.Height / compresionFactor)));
                        resizedBitmap.Save(currentProjectFolderPath + "/PPVerilogEngine//tempPictures//compressedPicture.png");

                        Bitmap colorSetBitmap = new Bitmap(resizedBitmap);
                        colorSetBitmap = limitColorBitmap(colorSetBitmap, maxColorBits);
                        colorSetBitmap.Save(currentProjectFolderPath + "/PPVerilogEngine//tempPictures//colorLimitedPicture.png");

                        int savedPixels = 0;
                        int usedPixels = 0;
                        writer.WriteLine(Environment.NewLine + getTabs(tabs) + "//Drawing picture with compression rate: " + compresionFactor + ":1");
                        for (int i = 0; i < colorSetBitmap.Height; i++)
                        {
                            int startingPixel = -1;
                            var startingColor = System.Drawing.Color.White;
                            for (int j = 0; j < colorSetBitmap.Width; j++)
                            {
                                System.Drawing.Color color = colorSetBitmap.GetPixel(j, i);
                                if (color.A > 100)
                                {
                                    if (startingPixel == -1)
                                    {
                                        startingPixel = j;
                                        startingColor = color;
                                    }
                                    else
                                    {
                                        if ((color.R != startingColor.R || color.G != startingColor.G || color.B != startingColor.B) || j == colorSetBitmap.Width - 1) //Not the same, write the old one  || From startingPixel to current-1 in width (j)
                                        {
                                      
                                                writer.Write(getTabs(tabs) + "if(yPixel>=" + (int)(finalLayout.Top + (i * compresionFactor)) + " && yPixel<" + (int)(finalLayout.Top + ((i + 1) * compresionFactor)) + " && xPixel>=" + (int)(finalLayout.Left + (startingPixel * compresionFactor)) + " && xPixel<" + (int)(finalLayout.Left + (j * compresionFactor)) + ") ");
                                                writer.WriteLine("{VGAr,VGAg,VGAb}={" + formatNumber("b", 8, Convert.ToString(startingColor.R, 2).PadLeft(8, '0')) + "," + formatNumber("b", 8, Convert.ToString(startingColor.G, 2).PadLeft(8, '0')) + "," + formatNumber("b", 8, Convert.ToString(startingColor.B, 2).PadLeft(8, '0')) + "};");

                                            

                                            startingColor = color;
                                            startingPixel = j;
                                            usedPixels++;
                                        }
                                        else
                                        {
                                            savedPixels++;
                                            //Do nothing, is still the same color, keep waiting until it changes.
                                        }
                                    }
                                }
                            }
                        }

                        Console.WriteLine(getTabs(3) + "Picture compressed at " + Math.Round((float)usedPixels / (baseBitmap.Width * baseBitmap.Height) * 100, 2) + "% of the original size!");
                    }

                }
            }
        }

        private Dictionary<string, string> getProperties(GemBox.Presentation.TextBox notes,string fromString="")
        {
            Dictionary<string, string> toReturn = new Dictionary<string, string>();
            string finalNotes = "";
            if (fromString=="")
            {
                if (notes == null) return toReturn;
                
                foreach (var line in notes.Paragraphs)
                {
                    foreach (var text in line.Elements)
                    {
                        string property = text.ToString();
                        finalNotes += property;

                    }
                }
            }else
            {
                finalNotes = fromString;
            }

            finalNotes = finalNotes.Replace("\n", "");

            List<string> properties = new List<string>();
            if(finalNotes.Contains(";"))
            {
                properties = finalNotes.Split(';').ToList();
            }
            else
            {
                properties.Add(finalNotes);
            }

            foreach (string propertyx in properties)
            {
                string property = propertyx;
                if (property.Contains("[") && property.Contains("]") && property.StartsWith("//") == false)
                {
                    property = property.Replace("[", "").Replace("]", "");
                    if (property.Contains("="))
                    {
                        toReturn.Add(property.Split('=')[0], property.Split('=')[1]);
                    }
                    else
                    {
                        toReturn.Add(property, "");
                    }
                   // Console.WriteLine("Property found: " + property);
                }
            }



            return toReturn;
        }

        private void drawBasicShapes(StreamWriter writer, Slide slide,int tabs)
        {
            //Draw shapes
            foreach(Shape shape in slide.Content.Drawings.OfType<Shape>())
            {
                Dictionary<string, string> properties = getProperties(shape.Text);
                if(shape.Format.Fill.FillType==FillFormatType.Solid)
                {
                    SolidFillFormat f = (SolidFillFormat)shape.Format.Fill;

                    //Find level of transparency
                    int allowedTransparencyLevel = 0;
                    if (properties.ContainsKey("TRANSPARENT")) allowedTransparencyLevel = 1;
                    if (properties.ContainsKey("ADVANCEDTRANSPARENT")) allowedTransparencyLevel = 2;

                    if (shape.ShapeType==ShapeGeometryType.Rectangle)
                    {
                        Console.WriteLine(getTabs(2) + "Writing solid shape: "+(properties.ContainsKey("NAME") ? properties["NAME"] : "UNNAMED"));


                        writer.WriteLine(Environment.NewLine + getTabs(tabs) + "//Drawing Solid shape \"" + (properties.ContainsKey("NAME")?properties["NAME"]:"UNNAMED") +"\"");                      
                        if (properties.ContainsKey("TRANSPARENT")) writer.WriteLine(getTabs(tabs)+"//   --> Allowed 50% transparent render");
                        if (properties.ContainsKey("ADVANCEDTRANSPARENT")) writer.WriteLine(getTabs(tabs) + "//   --> Allowed advanced transparent render");
                                                
                        //Draw shapes
                        writeSquareShapeColor(writer, f.Color,getScaledLayout(shape.Layout),tabs,shape.Format.Outline,properties.ContainsKey("BORDER"), allowedTransparencyLevel);
                    }                    
                }
            }

            
        }

        private Bitmap limitColorBitmap(Bitmap colorSetBitmap,int bitLimit)
        {
            int dividend = (int)(256 / (Math.Pow(2,bitLimit-1)));

            for(int i=0;i<colorSetBitmap.Width;i++)
            {
                for(int j=0;j<colorSetBitmap.Height;j++)
                {
                    System.Drawing.Color color = colorSetBitmap.GetPixel(i, j);
                    int r = (int)(Math.Round((double)color.R / dividend, 0) * dividend);
                    int g = (int)(Math.Round((double)color.G / dividend, 0) * dividend);
                    int b = (int)(Math.Round((double)color.B / dividend, 0) * dividend);
                    if (r > 255) r = 255;
                    if (g > 255) g = 255;
                    if (b > 255) b = 255;
                    color = System.Drawing.Color.FromArgb(color.A,r,g ,b);
                    colorSetBitmap.SetPixel(i,j,color);
                }
            }

            return colorSetBitmap;
        }

        System.Drawing.Color parseColor(string colorString)
        {
            try
            {
                if (colorString.StartsWith("#"))
                {
                    return System.Drawing.Color.FromArgb(255, 255, 255);
                }
                else
                {
                    return System.Drawing.Color.FromArgb(int.Parse(colorString.Split(',')[0]), int.Parse(colorString.Split(',')[1]), int.Parse(colorString.Split(',')[2]));
                }
            }catch(Exception ex)
            {
                Console.WriteLine("An error has occurred when parsing color {0}. {1}", colorString, ex.Message);
                return System.Drawing.Color.White;
            }
           
        }

        string getTabs(int number)
        {
            string toReturn="";

            for (int i = 0; i < number; i++) toReturn += "\t";

            return toReturn;
        }

        DrawingLayout getScaledLayout(DrawingLayout layout)
        {
            layout.Left = ((layout.Left / 72.0) / 10) * 640;
            layout.Width = ((layout.Width / 72.0) / 10) * 640;
            layout.Top = ((layout.Top / 72.0) / 7.5) * 480;
            layout.Height = ((layout.Height / 72.0) / 7.5) * 480;
            return layout;


        }

       

        void writeSquareShapeColor(StreamWriter writer, GemBox.Presentation.Color color,DrawingLayout scaledLayout,int tabs,LineFormat outline,bool borderEnabled, int allowedTransparencyLevel)
        {
            writer.WriteLine(getTabs(tabs) + "if(xPixel>" + (int)scaledLayout.Left.To(LengthUnit.Point) + " && xPixel<" + ((int)scaledLayout.Left.To(LengthUnit.Point) + (int)scaledLayout.Width.To(LengthUnit.Point)) +
                " && yPixel>" + (int)scaledLayout.Top.To(LengthUnit.Point) + " && yPixel<" + ((int)scaledLayout.Top.To(LengthUnit.Point) + (int)scaledLayout.Height.To(LengthUnit.Point)) + ")"+Environment.NewLine+getTabs(tabs)+"begin");

            if(allowedTransparencyLevel == 0 || color.A==255)  //No transparency allowed
            {
                writer.WriteLine(getTabs(tabs + 1) + "VGAr = " + formatNumber("b", 8, Convert.ToString(color.R, 2).PadLeft(8, '0')) + ";");
                writer.WriteLine(getTabs(tabs + 1) + "VGAg = " + formatNumber("b", 8, Convert.ToString(color.G, 2).PadLeft(8, '0')) + ";");
                writer.WriteLine(getTabs(tabs + 1) + "VGAb = " + formatNumber("b", 8, Convert.ToString(color.B, 2).PadLeft(8, '0')) + ";");
            }
            else
            { 
                if(allowedTransparencyLevel == 1 || color.A > 125 && color.A < 130)  //Basic transparency (50/50) allowed
                {
                    writer.WriteLine(getTabs(tabs + 1) + "VGAr = (" + formatNumber("b", 8, Convert.ToString(color.R, 2).PadLeft(8, '0')) + " + VGAr) / 2;");
                    writer.WriteLine(getTabs(tabs + 1) + "VGAg = (" + formatNumber("b", 8, Convert.ToString(color.G, 2).PadLeft(8, '0')) + " + VGAg) / 2;");  
                    writer.WriteLine(getTabs(tabs + 1) + "VGAb = (" + formatNumber("b", 8, Convert.ToString(color.B, 2).PadLeft(8, '0')) + " + VGAb) / 2;");
                }
                else  //Custom color based trnasparency allowed
                {
                    writer.WriteLine(getTabs(tabs + 1) + "VGAr = (" + formatNumber("b", 8, Convert.ToString((int)(color.R*(color.A/255.0)), 2).PadLeft(8, '0')) + " + ((" + (int)((color.A / 255.0) * 100)+" * VGAr) / 100));");
                    writer.WriteLine(getTabs(tabs + 1) + "VGAg = (" + formatNumber("b", 8, Convert.ToString((int)(color.G*(color.A / 255.0)), 2).PadLeft(8, '0')) + " + ((" + (int)((color.A / 255.0) * 100) + " * VGAg) / 100));");
                    writer.WriteLine(getTabs(tabs + 1) + "VGAb = (" + formatNumber("b", 8, Convert.ToString((int)(color.B * (color.A / 255.0)), 2).PadLeft(8, '0')) + " + ((" + (int)((color.A / 255.0) * 100) + " * VGAb) / 100));");
                }
            }

            if(borderEnabled)
            {
                writer.Write(getTabs(tabs + 1) + "if(xPixel<" + Math.Round((int)scaledLayout.Left.To(LengthUnit.Point) + 0.668f * (int)outline.Width.To(LengthUnit.Point),0) + " || " +
                   "xPixel>" + Math.Round((int)scaledLayout.Left.To(LengthUnit.Point) + (int)scaledLayout.Width.To(LengthUnit.Point) - 0.668f * (int)outline.Width.To(LengthUnit.Point),0) + " || "+
                    "yPixel<" + Math.Round((int)scaledLayout.Top.To(LengthUnit.Point) + 0.668f * (int)outline.Width.To(LengthUnit.Point), 0) + " || " +
                   "yPixel>" + Math.Round((int)scaledLayout.Top.To(LengthUnit.Point) + (int)scaledLayout.Height.To(LengthUnit.Point) - 0.668f * (int)outline.Width.To(LengthUnit.Point), 0) + ")");
                writer.WriteLine("    //Drawing border");

                
                writer.WriteLine(getTabs(tabs + 1) + "begin");

                SolidFillFormat outlineFill = (SolidFillFormat)outline.Fill;

                if (allowedTransparencyLevel == 0f || outlineFill.Color.A==255)
                {
                    writer.WriteLine(getTabs(tabs + 2) + "VGAr = " + formatNumber("b", 8, Convert.ToString(outlineFill.Color.R, 2).PadLeft(8, '0')) + ";");
                    writer.WriteLine(getTabs(tabs + 2) + "VGAg = " + formatNumber("b", 8, Convert.ToString(outlineFill.Color.G, 2).PadLeft(8, '0')) + ";");
                    writer.WriteLine(getTabs(tabs + 2) + "VGAb = " + formatNumber("b", 8, Convert.ToString(outlineFill.Color.B, 2).PadLeft(8, '0')) + ";");
                }
                else
                {
                    if (allowedTransparencyLevel==1 || outlineFill.Color.A > 125 && outlineFill.Color.A < 130)
                    {
                        writer.WriteLine(getTabs(tabs + 2) + "VGAr = (" + formatNumber("b", 8, Convert.ToString(outlineFill.Color.R, 2).PadLeft(8, '0')) + " + VGAr) / 2;");
                        writer.WriteLine(getTabs(tabs + 2) + "VGAg = (" + formatNumber("b", 8, Convert.ToString(outlineFill.Color.G, 2).PadLeft(8, '0')) + " + VGAg) / 2;");
                        writer.WriteLine(getTabs(tabs + 2) + "VGAb = (" + formatNumber("b", 8, Convert.ToString(outlineFill.Color.B, 2).PadLeft(8, '0')) + " + VGAb) / 2;");
                    }
                    else
                    {
                        writer.WriteLine(getTabs(tabs + 2) + "VGAr = (" + formatNumber("b", 8, Convert.ToString((int)(outlineFill.Color.R * (outlineFill.Color.A/100)), 2).PadLeft(8, '0')) + " + ((" + (int)((outlineFill.Color.A / 100) * 100) + " * VGAr) / 100));");
                        writer.WriteLine(getTabs(tabs + 2) + "VGAg = (" + formatNumber("b", 8, Convert.ToString((int)(outlineFill.Color.G * (outlineFill.Color.A / 100)), 2).PadLeft(8, '0')) + " + ((" + (int)((outlineFill.Color.A / 100) * 100) + " * VGAg) / 100));");
                        writer.WriteLine(getTabs(tabs + 2) + "VGAb = (" + formatNumber("b", 8, Convert.ToString((int)(outlineFill.Color.B * (outlineFill.Color.A / 100)), 2).PadLeft(8, '0')) + " + ((" + (int)((outlineFill.Color.A / 100) * 100) + " * VGAb) / 100));");

                    }
                }

                writer.WriteLine(getTabs(tabs + 1) + "end");
            }

            writer.WriteLine(getTabs(tabs) + "end");
        }

        void writeMouse(StreamWriter writer, GemBox.Presentation.Color color, int tabs,Size size)
        {

            writer.WriteLine("\n" + getTabs(tabs) + "//Drawing the mouse");
            writer.WriteLine(getTabs(tabs) + "if(xPixel>mouseX && xPixel<(mouseX+"+size.Width+") && yPixel>mouseY && yPixel<(mouseY+"+size.Height+"))" + Environment.NewLine + getTabs(tabs) + "begin");

           
                writer.WriteLine(getTabs(tabs + 1) + "VGAr = " + formatNumber("b", 8, Convert.ToString(color.R, 2).PadLeft(8, '0')) + ";");
                writer.WriteLine(getTabs(tabs + 1) + "VGAg = " + formatNumber("b", 8, Convert.ToString(color.G, 2).PadLeft(8, '0')) + ";");
                writer.WriteLine(getTabs(tabs + 1) + "VGAb = " + formatNumber("b", 8, Convert.ToString(color.B, 2).PadLeft(8, '0')) + ";");            
            

            writer.WriteLine(getTabs(tabs) + "end");
        }

        string formatNumber(string type,int length,string value)
        {
            return String.Format("{0}'{1}{2}",length,type,value);
        }

   
        private void saveProjectToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if(currentProjectFilePath=="")
            {
                if(saveFileDialog1.ShowDialog()==DialogResult.OK)
                {
                    currentProjectFilePath = saveFileDialog1.FileName;
                    currentProjectFolderPath = new FileInfo(currentProjectFilePath).Directory.FullName;
                }
            }

            if(currentProjectFilePath!="")
            {
                using (StreamWriter writer = new StreamWriter(currentProjectFilePath))
                {
                    if (textBoxProjectName.Text == "") textBoxProjectName.Text = Interaction.InputBox("Project name:", "Project name",new FileInfo(currentProjectFilePath).Directory.Name);
                    writer.WriteLine(textBoxProjectName.Text);
                    writer.WriteLine(checkBoxAutoCompile.Checked.ToString());
                }
            }
        }

        private void openProjectToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                currentProjectFilePath = openFileDialog1.FileName;
                currentProjectFolderPath = new FileInfo(currentProjectFilePath).Directory.FullName;
                using (StreamReader reader = new StreamReader(currentProjectFilePath))
                {
                    textBoxProjectName.Text = reader.ReadLine();
                    checkBoxAutoCompile.Checked = bool.Parse(reader.ReadLine());
                }
            }

            watcher = new FileSystemWatcher();
            watcher.Path = currentProjectFolderPath+ "/PPVerilogEngine";
            watcher.NotifyFilter = NotifyFilters.LastAccess | NotifyFilters.LastWrite
               | NotifyFilters.FileName | NotifyFilters.DirectoryName;
            watcher.Filter = "*.pptx";

            // Add event handlers.
            watcher.Changed += new FileSystemEventHandler(OnChanged);
            watcher.Created += new FileSystemEventHandler(OnChanged);
            watcher.Deleted += new FileSystemEventHandler(OnChanged);
            watcher.Renamed += new RenamedEventHandler(OnChanged);

            // Begin watching.
            watcher.EnableRaisingEvents = true;
        }

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            if(checkBoxAutoCompile.Checked)this.Invoke((MethodInvoker)delegate(){ button1.PerformClick(); });
        }
    }




    public class MultiTextWriter : TextWriter
    {
        private IEnumerable<TextWriter> writers;
        public MultiTextWriter(IEnumerable<TextWriter> writers)
        {
            this.writers = writers.ToList();
        }
        public MultiTextWriter(params TextWriter[] writers)
        {
            this.writers = writers;
        }

        public override void Write(char value)
        {
            foreach (var writer in writers)
                writer.Write(value);
        }

        public override void Write(string value)
        {
            foreach (var writer in writers)
                writer.Write(value);
        }

        public override void Flush()
        {
            foreach (var writer in writers)
                writer.Flush();
        }

        public override void Close()
        {
            foreach (var writer in writers)
                writer.Close();
        }

        public override Encoding Encoding
        {
            get { return Encoding.ASCII; }
        }
    }

    public class ControlWriter : TextWriter
    {
        private Control textbox;
        public ControlWriter(Control textbox)
        {
            this.textbox = textbox;
        }

        public override void Write(char value)
        {
            textbox.Invoke((MethodInvoker)delegate () {
                textbox.Text += value;
            });            
        }

        public override void Write(string value)
        {
            textbox.Invoke((MethodInvoker)delegate () {
                textbox.Text += value;
            });
        }

        public override Encoding Encoding
        {
            get { return Encoding.ASCII; }
        }
    }
}
