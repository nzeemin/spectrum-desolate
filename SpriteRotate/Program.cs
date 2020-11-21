using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;
using System.Linq;
using System.Text;
// ReSharper disable IdentifierTypo

namespace SpriteRotate
{
    class Program
    {
        private static byte[] memdmp = new byte[65536];

        private static readonly Color[] colorsY = new Color[]
        {
            Color.AntiqueWhite,
            Color.FromArgb(255, 120, 120, 120),
            Color.FromArgb(255, 180, 180, 180),
            Color.Black
        };

        private static readonly Color[] colorsB = new Color[]
        {
            Color.PowderBlue,
            Color.FromArgb(255, 120, 120, 120),
            Color.FromArgb(255, 180, 180, 180),
            Color.Black
        };

        private static int[] memchanges = new int[65536];

        static void Main(string[] args)
        {
            ParseMemoryDump();

            //var savnames = Directory.GetFiles(".", "*.sav");
            //PreProcessSavs(savnames);
            //foreach (var savname in savnames)
            //{
            //    Console.WriteLine(savname);
            //    ProcessSav(savname);
            //}

            //ProcessRooms();
            ProcessRoomsNewTiles();
            //ProcessRoomsMap();

            //DumpChangedAreas();
            //DumpArchivedStrings();
            //PrepareArchivedStrings();
            //PrepareLineAddresses();
            //PrepareFontProto();
            PrepareTilesets();
            //PrepareCreditsMargins();

            //TestNewEncode();
        }

        static void ParseMemoryDump()
        {
            string textdump = File.ReadAllText("desolatemenu.txt");
            var lines = textdump.Split(new[] {Environment.NewLine}, StringSplitOptions.None);
            //line 16491 RAM 00/01
            for (int linei = 16490; linei < 17514; linei++)
            {
                string line = lines[linei];
                var tokens = line.Split(' ');
                var memno = int.Parse(tokens[0]); // 0/1
                var addr = Convert.ToInt32(tokens[1].Substring(0, 4), 16);
                addr += memno == 0 ? 0xC000 : 0x8000;
                for (int i = 0; i < 32; i++)
                {
                    byte v = Convert.ToByte(tokens[i + 2], 16);
                    memdmp[addr + i] = v;
                }
            }

            File.WriteAllBytes("memdmp.bin", memdmp);
            Console.WriteLine("memdmp.bin saved");
        }

        static void PrepareFontProto()
        {
            using (var writer = new StreamWriter("desolfont.asm"))
            {
                Bitmap bmp = new Bitmap(@"..\fontproto.png");

                writer.WriteLine("FontProto:");
                for (int row = 0; row < 6; row++)
                {
                    for (int col = 0; col < 16; col++)
                    {
                        int x = col * 13;
                        int y = 2 + row * 15;
                        var octets = new byte[11];

                        for (int i = 0; i < 11; i++)
                        {
                            int val = 0;
                            for (int b = 0; b < 8; b++)
                            {
                                Color c = bmp.GetPixel(x + b, y + i);
                                int v = (c.GetBrightness() > 0.5f) ? 0 : 1;
                                val |= (v << (7 - b));
                            }

                            octets[i] = (byte) val;
                        }

                        bool lowered = octets[10] != 0;
                        byte mask = 0;
                        for (int i = 0; i < 11; i++)
                            mask |= octets[i];
                        if (mask == 0)
                            continue; // Skip empty symbol

                        int width = 0;
                        for (int b = 0; b < 8; b++)
                        {
                            if (((mask >> (7 - b)) & 1) == 1)
                                width = b + 1;
                        }

                        byte descbyte = (byte) ((lowered ? 128 : 0) + width);

                        writer.Write($"  DB ${descbyte:X2}, ");
                        var start = lowered ? 1 : 0;
                        for (int i = start; i < start + 10; i++)
                        {
                            writer.Write($"${octets[i]:X2}");
                            if (i < start + 9) writer.Write(",");
                        }

                        var ch = (char) (' ' + col + row * 16);
                        writer.Write($"  ; {ch}");
                        writer.WriteLine();
                    }
                }

                Console.WriteLine("desolfont.asm saved");
            }
        }

        static void PrepareTilesets()
        {
            using (var bmp = new Bitmap(@"..\tiles.png"))
            using (var writer = new StreamWriter("desoltils.asm"))
            {
                writer.WriteLine(";");
                writer.WriteLine("; Tileset 1, 122 tiles 16x16 no mask");
                writer.WriteLine("Tileset1:");
                PrepareTilesetImpl(bmp, 8, 122, writer);

                writer.WriteLine(";");
                writer.WriteLine("; Sprites, 36 tiles 16x8 with mask");
                writer.WriteLine("Sprites:");
                PrepareTilesetMaskedImpl(bmp, 168, 36, writer);

                writer.WriteLine(";");
                writer.WriteLine("; Tileset 2, 127 tiles 16x8 with mask");
                writer.WriteLine("Tileset2:");
                PrepareTilesetMaskedImpl(bmp, 228, 126, writer);

                writer.WriteLine(";");

                PrepareTileset3(bmp, writer);
            }
            Console.WriteLine("desoltils.asm saved");
        }

        static void PrepareTilesetImpl(Bitmap bmp, int x0, int tilescount, StreamWriter writer)
        {
            for (int tile = 0; tile < tilescount; tile++)
            {
                var words = new int[16];
                int x = x0 + (tile / 16) * 20;
                int y = 8 + (tile % 16) * 20;
                for (int i = 0; i < 16; i++)
                {
                    int val = 0;
                    for (int b = 0; b < 16; b++)
                    {
                        Color c = bmp.GetPixel(x + b, y + i);
                        int v = (c.GetBrightness() > 0.2f) ? 0 : 1;
                        val |= (v << (15 - b));
                    }
                    words[i] = val;
                }

                writer.Write("  DB ");
                for (int i = 0; i < 16; i++)
                {
                    writer.Write($"${(words[i] >> 8):X2},${(words[i] & 0xFF):X2}");
                    if (i < 15) writer.Write(",");
                }

                writer.WriteLine();
            }
        }

        static void PrepareTilesetMaskedImpl(Bitmap bmp, int x0, int tilescount, StreamWriter writer)
        {
            for (int tile = 0; tile < tilescount; tile++)
            {
                var words = new int[8];
                var masks = new int[8];
                int x = x0 + (tile / 16) * 20;
                int y = 8 + (tile % 16) * 20;
                for (int i = 0; i < 8; i++)
                {
                    int val = 0;
                    int valm = 0;
                    for (int b = 0; b < 16; b++)
                    {
                        Color c = bmp.GetPixel(x + b, y + i * 2);
                        int v = (c.GetBrightness() > 0.2f) ? 0 : 1;
                        val |= (v << (15 - b));
                        int vm = (c.R == 120 && c.G == 120 && c.B == 120) ? 1 : 0;
                        valm |= (vm << (15 - b));
                    }

                    words[i] = val;
                    masks[i] = valm;
                }

                writer.Write("  DB ");
                for (int i = 0; i < 8; i++)
                {
                    writer.Write($"${(masks[i] >> 8):X2},${(words[i] >> 8):X2},");
                    writer.Write($"${(masks[i] & 0xFF):X2},${(words[i] & 0xFF):X2}");
                    if (i < 7) writer.Write(",");
                }

                writer.WriteLine();
            }
        }

        static void PrepareTileset3(Bitmap bmp, StreamWriter writer)
        {
            writer.WriteLine("; Tiles inventory items, 14 tiles 16x16");
            writer.WriteLine("Tileset3:");
            for (int tile = 0; tile < 16; tile++)
            {
                var words = new int[16];
                int x = 392;
                int y = 8 + tile * 20;
                for (int i = 0; i < 16; i++)
                {
                    int val = 0;
                    for (int b = 0; b < 16; b++)
                    {
                        Color c = bmp.GetPixel(x + b, y + i);
                        int v = (c.GetBrightness() > 0.5f) ? 0 : 1;
                        val |= (v << (15 - b));
                    }

                    words[i] = val;
                }

                writer.Write("  DB ");
                for (int i = 0; i < 16; i++)
                {
                    writer.Write($"${(words[i] >> 8):X2},${(words[i] & 0xFF):X2}");
                    if (i < 15) writer.Write(",");
                }

                writer.WriteLine();
            }
        }

        static void PrepareLineAddresses()
        {
            using (var file = new StreamWriter("lineaddrs.txt"))
            {
                for (int line = 40; line < 40 + 128; line += 2)
                {
                    if ((line - 40) % 16 == 0)
                        file.Write("  DW ");
                    int addr = 0x4000 + ((line & 0x7) << 8) + ((line & 0x38) << 2) + ((line & 0xC0) << 5) + 4;
                    file.Write($"${addr:X4}");
                    if ((line - 40) % 16 < 14)
                        file.Write(",");
                    else
                        file.WriteLine();
                }
            }
        }

        static void DumpArchivedStrings()
        {
            byte[] desdata = File.ReadAllBytes("DesData.8xp");

            var offsets = new Dictionary<int, int>();
            for (int oaddr = 0xE09B; oaddr < 0xE147; oaddr += 2)
            {
                var offset = memdmp[oaddr] + memdmp[oaddr + 1] * 256;
                offsets.Add(oaddr, offset);
            }

            for (int oaddr = 0xE029; oaddr < 0xE099; oaddr += 2)
            {
                var offset = memdmp[oaddr] + memdmp[oaddr + 1] * 256;
                offsets.Add(oaddr, offset);
            }

            using (var filetxt = new StreamWriter("strings.txt"))
            using (var fileasm = new StreamWriter("strings.asm"))
            {
                StringBuilder sb = new StringBuilder();
                var offsetsOrderedKeys = offsets.OrderBy(x => x.Key).AsEnumerable();
                foreach (var p in offsetsOrderedKeys)
                {
                    var addr = p.Key;
                    var offset = p.Value;
                    sb.Clear();
                    for (;;)
                    {
                        var v = desdata[offset + 0x48];
                        if (v == 0)
                            break;
                        sb.Append((char) v);
                        offset++;
                    }

                    filetxt.WriteLine($"W ${addr:X4},2 -> \"{sb.ToString()}\"");
                    fileasm.WriteLine($"S{addr:X4}: DEFM \"{sb.ToString()}\",0");
                }
            }

            Console.WriteLine("strings.txt ans strings.asm saved");
        }

        static void DumpChangedAreas()
        {
            using (var file = new StreamWriter("memchanged.txt"))
            {
                var start = int.MaxValue;
                for (int a = 0; a < 65536; a++)
                {
                    bool changed = memchanges[a] > 0;
                    if (!changed && start < a)
                    {
                        file.WriteLine($"{start:X4}-{(a - 1):X4}");
                        start = int.MaxValue;
                    }

                    if (changed && start == int.MaxValue)
                    {
                        start = a;
                    }
                }
            }

            Console.WriteLine("memchanged.txt saved");
        }

        static void PrepareArchivedStrings()
        {
            byte[] desdata = File.ReadAllBytes("DesData.8xp");

            using (var file = new StreamWriter("strings.asm"))
            {
                StringBuilder sb = new StringBuilder();
                var eaddr = 0xE09B; // address in the memory dump
                while (eaddr < 0xE147)
                {
                    var offset = memdmp[eaddr] + memdmp[eaddr + 1] * 256;
                    sb.Clear();
                    for (;;)
                    {
                        var v = desdata[offset + 0x48];
                        if (v == 0)
                            break;
                        sb.Append((char) v);
                        offset++;
                    }

                    file.WriteLine($"S{eaddr:X4}: DEFM \"{sb.ToString()}\",0");
                    eaddr += 2;
                }
            }

            Console.WriteLine("strings.asm saved");
        }

        static void PreProcessSavs(string[] savnames)
        {
            List<byte[]> mems = new List<byte[]>();

            foreach (var savname in savnames)
            {
                byte[] mem = new byte[65536];
                byte[] savdmp = File.ReadAllBytes(savname);
                Array.Copy(savdmp, 0x80D7B, mem, 0xC000, 16384);
                Array.Copy(savdmp, 0x84D7B, mem, 0x8000, 16384);
                mems.Add(mem);
            }

            for (int i = 0; i < mems.Count; i++)
            {
                for (int j = 0; j < mems.Count; j++)
                {
                    if (i == j)
                        continue;

                    byte[] mem1 = mems[i];
                    byte[] mem2 = mems[j];

                    for (int a = 0; a < 65536; a++)
                    {
                        if (mem1[a] != mem2[a])
                            memchanges[a]++;
                    }
                }
            }

            mems.Clear();
        }

        static void ProcessSav(string infilename)
        {
            byte[] savdmp = File.ReadAllBytes(infilename);

            Array.Copy(savdmp, 0x80D7B, memdmp, 0xC000, 16384);
            Array.Copy(savdmp, 0x84D7B, memdmp, 0x8000, 16384);

            var outfilename = Path.GetFileNameWithoutExtension(infilename) + ".bin";
            File.WriteAllBytes(outfilename, memdmp);

            var bmp = new Bitmap(128 * 10 + 12, 64 * 8 + 24, PixelFormat.Format32bppArgb);
            ProcessSprites8x8x2(bmp, 6);
            //ProcessSprites8x8x4(bmp, 12 + 32 * 8);
            ProcessTiles8x8x4(bmp, 978, 42 + 32 * 8, 0xE147, 0xEB27); // Tileset 1
            ProcessTiles8x8x4(bmp, 1080, 42 + 32 * 8, 0xEB39, 0xF329); // Tileset 2
            ProcessTiles8x8x4(bmp, 1162, 42 + 32 * 8, 0xF34F, 0xF34F + 0xE0);
            ProcessScreen(bmp, 6 + 180, 42 + 32 * 8, 0x9340, 0x9872);
            ProcessScreen(bmp, 6 + 310, 42 + 32 * 8, 0xA28F, 0xA58F);
            ProcessSavRoom(bmp, 6 + 310, 42 + 32 * 8 + 70, 0xE147); // Room in Tileset 1
            ProcessSavRoom(bmp, 6 + 410, 42 + 32 * 8 + 70, 0xEB39); // Room in Tileset 2
            var bmpfilename = Path.GetFileNameWithoutExtension(infilename) + "-8.png";
            bmp.Save(bmpfilename);

            //FileStream fs = new FileStream("SPRITE.MAC", FileMode.Create);
            //StreamWriter writer = new StreamWriter(fs);
            //writer.WriteLine("; START OF SPRITE.MAC");
            //writer.WriteLine();

            //writer.WriteLine("; END OF SPRITE.MAC");

            //writer.Flush();

        }

        static void ProcessSprites8x8x2(Bitmap bmp, int y)
        {
            Graphics g = Graphics.FromImage(bmp);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            var font = new Font("Tahoma", 8);

            int addr = 0x8000;
            for (int col = 0; col < 128; col++)
            {
                g.TranslateTransform(col * 10 + 3, 28);
                g.RotateTransform(-90);
                g.DrawString(addr.ToString("X4"), font, Brushes.Black, 0, 0);
                g.ResetTransform();

                for (int row = 0; row < 32 * 8; row++)
                {
                    int x = col * 10 + 6;
                    var val = memdmp[addr];
                    for (int b = 0; b < 8; b++)
                    {
                        int v = (val << b) & 128;
                        var c = v == 0 ? Color.AntiqueWhite : Color.Black;
                        //if (addr >= 0x9240 && addr < 0x9A72)
                        //    c = v == 0 ? Color.PowderBlue : Color.Black;
                        //if (addr >= 0xA18F && addr < 0xA78F)
                        //    c = v == 0 ? Color.PowderBlue : Color.Black;
                        if (memchanges[addr] > 0)
                            c = v == 0 ? Color.MistyRose : Color.DarkRed;
                        bmp.SetPixel(x + b, row + 30, c);
                    }

                    addr++;
                }
            }

            g.Flush();
            //Console.WriteLine($"{addr:X}");
        }

        static void ProcessSprites8x8x4(Bitmap bmp, int y)
        {
            int addr = 0x8000;
            for (int col = 0; col < 97; col++)
            {
                int x = col * 10 + 6;
                for (int row = 0; row < 16; row++)
                {
                    for (int s = 0; s < 8; s++)
                    {
                        var val1 = memdmp[addr];
                        var val2 = memdmp[addr + 8];
                        for (int b = 0; b < 8; b++)
                        {
                            int v1 = (val1 << b) & 128;
                            int v2 = (val2 << b) & 128;
                            int v = (v1 >> 7) | (v2 >> 6);
                            Color c = colorsY[v];
                            bmp.SetPixel(x + b, row * 8 + s + y, c);
                        }

                        addr++;
                    }

                    addr += 8;
                }
            }

            //Console.WriteLine($"{addr:X}");
        }

        static void ProcessTiles8x8x4(Bitmap bmp, int x0, int y0, int addr, int addrend)
        {
            for (int col = 0; col < 18; col++)
            {
                int x = col * 10 + x0;
                for (int row = 0; row < 16; row++)
                {
                    int y = row * 10 + y0;
                    for (int s = 0; s < 8; s++)
                    {
                        var val1 = memdmp[addr];
                        var val2 = memdmp[addr + 8];
                        for (int b = 0; b < 8; b++)
                        {
                            int v1 = (val1 << b) & 128;
                            int v2 = (val2 << b) & 128;
                            int v = (v1 >> 7) | (v2 >> 6);
                            Color c = colorsB[v];
                            bmp.SetPixel(x + b, y, c);
                        }

                        addr++;
                        y++;
                    }

                    addr += 8;
                    if (addr >= addrend)
                        break;
                }

                if (addr >= addrend)
                    break;
            }

            //Console.WriteLine($"{addr:X}");
        }

        static void ProcessScreen(Bitmap bmp, int x0, int y0, int addr1, int addr2)
        {
            //Console.WriteLine($"{addr1:X} {addr2:X}");
            for (int col = 0; col < 8; col++)
            {
                for (int row = 0; row < 8; row++)
                {
                    for (int s = 0; s < 12; s++)
                    {
                        var val1 = memdmp[addr1++];
                        var val2 = memdmp[addr2++];
                        for (int b = 0; b < 8; b++)
                        {
                            int x = s * 8 + b + x0;
                            int y = col * 8 + row + y0;
                            int v1 = (val1 << b) & 128;
                            int v2 = (val2 << b) & 128;
                            int v = (v1 >> 7) | (v2 >> 6);
                            Color c = colorsB[v];
                            bmp.SetPixel(x, y, c);
                        }
                    }
                }
            }

            //Console.WriteLine($"{addr1:X} {addr2:X}");
        }

        static void ProcessSavRoom(Bitmap bmp, int x0, int y0, int tileaddr)
        {
            int addr = 0xDBF5; // Здесь комната в тайлах
            for (int row = 0; row < 8; row++)
            {
                for (int col = 0; col < 12; col++)
                {
                    var tile = memdmp[addr++];
                    int x = col * 8 + x0;
                    int y = row * 8 + y0;

                    var taddr = tileaddr + tile * 16;
                    for (int s = 0; s < 8; s++)
                    {
                        var val1 = memdmp[taddr];
                        var val2 = memdmp[taddr + 8];
                        for (int b = 0; b < 8; b++)
                        {
                            int v1 = (val1 << b) & 128;
                            int v2 = (val2 << b) & 128;
                            int v = (v1 >> 7) | (v2 >> 6);
                            Color c = colorsY[v];
                            bmp.SetPixel(x + b, y, c);
                        }

                        taddr++;
                        y++;
                    }
                }
            }
        }

        static void ProcessRooms()
        {
            var bmp = new Bitmap(106 * 13 + 12, 74 * 6 + 16, PixelFormat.Format32bppArgb);
            int x0 = 8, y0 = 8;

            byte[] savdmp = File.ReadAllBytes("memdmp.bin");
            Array.Copy(savdmp, 0, memdmp, 0, 65536);

            var filerooms = new StreamWriter("rooms.txt");

            Graphics g = Graphics.FromImage(bmp);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            var font = new Font("Tahoma", 8);

            int addr, xr, yr;
            for (int r = 0; r < 72; r++)
            {
                int aaddr = 0xDE97 + r * 2;
                addr = memdmp[aaddr] + memdmp[aaddr + 1] * 256;
                if (addr == 0xD6CE)
                    continue; // Not a valid room
                byte[] room = DecodeRoom(addr, 96);

                xr = x0 + (r / 6) * 106;
                yr = y0 + (r % 6) * 74 + 6;

                DrawRoom(bmp, xr, yr, room, 0xE147);

                g.DrawString($"{r}: {addr:X4}", font, Brushes.Navy, xr, yr - 12);

                //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room #{r}");
            }

            addr = 0xEB27;
            xr = x0 + 12 * 106;
            yr = y0 + 0 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF329;
            xr = x0 + 12 * 106;
            yr = y0 + 1 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF42F;
            xr = x0 + 12 * 106;
            yr = y0 + 2 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF468;
            xr = x0 + 12 * 106;
            yr = y0 + 3 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF4B5;
            xr = x0 + 12 * 106;
            yr = y0 + 4 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF515;
            xr = x0 + 12 * 106;
            yr = y0 + 5 * 74 + 6;
            DrawRoom(bmp, xr, yr, DecodeRoom(addr, 96), 0xE147);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            // Room description blocks
            for (int r = 0; r < 72; r++)
            {
                int daddr = 0xDF27 + r * 2;
                addr = memdmp[daddr] + memdmp[daddr + 1] * 256;
                int addrnext = addr + 96;
                if (r < 71)
                {
                    int daddrnext = daddr + 2;
                    addrnext = memdmp[daddrnext] + memdmp[daddrnext + 1] * 256;
                }

                //roomlen = addrnext - addr;

                //filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room #{r} desc");
            }

            filerooms.Flush();

            var roomsfilename = "rooms.png";
            bmp.Save(roomsfilename);
            Console.WriteLine($"{roomsfilename} saved");
        }

        static void ProcessRoomsNewTiles()
        {
            using (var bmp = new Bitmap(106 * 2 * 13 + 16, 74 * 2 * 6 + 16, PixelFormat.Format32bppArgb))
            using (var bmpTiles = new Bitmap(@"..\tiles.png"))
            {
                // Prepare tiles bitmap
                for (int x = 0; x < bmpTiles.Width; x++)
                for (int y = 0; y < bmpTiles.Height; y++)
                {
                    Color c = bmpTiles.GetPixel(x, y);
                    Color cn = (c.GetBrightness() > 0.2f) ? Color.AntiqueWhite : Color.Black;
                    bmpTiles.SetPixel(x, y, cn);
                }

                int x0 = 8, y0 = 8;

                byte[] savdmp = File.ReadAllBytes("memdmp.bin");
                Array.Copy(savdmp, 0, memdmp, 0, 65536);

                Graphics g = Graphics.FromImage(bmp);
                //g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                //g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
                var font = new Font("Tahoma", 8);

                int addr, xr, yr;
                for (int r = 0; r < 72; r++)
                {
                    if (RoomsNotUsed.Contains(r))
                        continue;
                    int aaddr = 0xDE97 + r * 2;
                    addr = memdmp[aaddr] + memdmp[aaddr + 1] * 256;
                    if (addr == 0xD6CE)
                        continue; // Not a valid room
                    byte[] room = DecodeRoom(addr, 96);

                    xr = x0 + (r / 6) * 106 * 2;
                    yr = y0 + (r % 6) * 74 * 2 + 6;

                    DrawRoomNewTiles(g, xr, yr, room, bmpTiles);

                    g.DrawString($"{r}: {addr:X4}", font, Brushes.Navy, xr, yr - 12);
                }

                var roomsfilename = "roomsnew.png";
                bmp.Save(roomsfilename);
                Console.WriteLine($"{roomsfilename} saved");
            }
        }

        static Color GetRoomPassageColorByAccessLevel(int access)
        {
            switch (access)
            {
                case 1:
                    return Color.Goldenrod;
                case 2:
                    return Color.Salmon;
                case 3:
                    return Color.Orange;
                case 4:
                    return Color.OrangeRed;
                default:
                    return Color.Aquamarine;
            }
        }

        static readonly int[] RoomsNotUsed = {6, 23, 25, 34, 36, 58};

        static void ProcessRoomsMap()
        {
            const int colwid = 120;
            const int rowhei = 80;

            var bmp = new Bitmap(colwid * 7 + 40, rowhei * 14 + 40, PixelFormat.Format32bppArgb);

            byte[] savdmp = File.ReadAllBytes("memdmp.bin");
            Array.Copy(savdmp, 0, memdmp, 0, 65536);

            var fileroomdescs = new StreamWriter("roomdescs.txt");

            Graphics g = Graphics.FromImage(bmp);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            var font = new Font("Tahoma", 8);

            // Title screen
            DrawRoom(bmp, 20, 20, DecodeRoom(0xF4B5, 96), 0xEB39);

            g.DrawString("Access Levels", font, Brushes.Navy, 20, 100);
            for (int i = 0; i < 5; i++)
            {
                var accesscolor = GetRoomPassageColorByAccessLevel(i);
                var pen = new Pen(accesscolor, 18);
                int x = 30;
                int y = 140 + i * 30;
                g.DrawLine(pen, x + 10, y, x + 70, y);
                var label = i == 0 ? "Free Pass" : $"Level {i}";
                g.DrawString(label, font, Brushes.Navy, x, y - 22);
            }

            int[] coords = new[]
            {
                //       --0-  --1-  --2-  --3-  --4-  --5-  --6   --7-  --8-  --9-
                /*  0 */ 1, 0, 1, 1, 1, 2, 2, 2, 2, 1, 1, 3, 0, 4, 2, 4, 1, 5, 2, 5,
                /*  1 */ 2, 3, 3, 3, 3, 2, 3, 1, 3, 0, 2, 0, 4, 0, 4, 1, 4, 2, 4, 3,
                /*  2 */ 4, 4, 4, 5, 5, 0, 6, 1, 5, 2, 6, 3, 5, 4, 5, 5, 3, 4, 3, 5,
                /*  3 */ 5, 6, 4, 6, 3, 6, 3, 7, 0, 6, 2, 6, 0, 0, 2, 7, 1, 7, 1, 8,
                /*  4 */ 1, 9, 1,10, 4, 7, 5, 7, 4, 8, 5, 8, 3, 8, 3, 9, 2, 8, 2, 9,
                /*  5 */ 2,10, 3,10, 4,10, 4, 9, 5, 9, 5,10, 5,11, 4,11, 0,11, 2,11,
                /*  6 */ 1,11, 1,12, 2,12, 3,12, 4,12, 5,12, 1,13, 2,13, 3,13, 4,13,
                /*  7 */ 5,13, 6,13
            };

            byte roomdescmax = 0;
            for (int r = 0; r < coords.Length / 2; r++)
            {
                if (RoomsNotUsed.Contains(r))
                    continue;

                int daaddr = 0xDF27 + r * 2;
                int daddr = memdmp[daaddr] + memdmp[daaddr + 1] * 256;
                byte[] rdesc = DecodeRoom(daddr, 49);

                fileroomdescs.WriteLine($"Room #{r} description:");
                fileroomdescs.WriteLine(" 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F");
                for (int i = 0; i < rdesc.Length; i++)
                {
                    if (rdesc[i] > roomdescmax)
                        roomdescmax = rdesc[i];
                    if (rdesc[i] == 0x61)
                        fileroomdescs.Write("--");
                    else
                        fileroomdescs.Write($"{rdesc[i]:X2}");
                    if (i >= 28 && i < 31 || i >= 35 && i < 38 || i >= 39 && i < 42)
                        fileroomdescs.Write("=");
                    else
                        fileroomdescs.Write(" ");
                    if (i % 16 == 15) fileroomdescs.WriteLine();
                }
                fileroomdescs.WriteLine();

                int xr = coords[r * 2] * colwid + 20 + 48;
                int yr = coords[r * 2 + 1] * rowhei + 20 + 32;

                int roomdown = rdesc[35];
                if (roomdown < 72)
                {
                    var accesscolor = GetRoomPassageColorByAccessLevel(rdesc[28]);
                    var pen = new Pen(accesscolor, 18);
                    int x = coords[roomdown * 2] * colwid + 20 + 48;
                    int y = coords[roomdown * 2 + 1] * rowhei + 20 + 32;
                    g.DrawLine(pen, xr, yr + 24, x, y - 24);
                }
                int roomright = rdesc[38];
                if (roomright < 72)
                {
                    var accesscolor = GetRoomPassageColorByAccessLevel(rdesc[31]);
                    var pen = new Pen(accesscolor, 18);
                    int x = coords[roomright * 2] * colwid + 20 + 48;
                    int y = coords[roomright * 2 + 1] * rowhei + 20 + 32;
                    g.DrawLine(pen, xr + 32, yr, x - 32, y);
                }
            }

            byte roommax = 0;
            for (int r = 0; r < coords.Length / 2; r++)
            {
                if (RoomsNotUsed.Contains(r))
                    continue;

                int aaddr = 0xDE97 + r * 2;
                int addr = memdmp[aaddr] + memdmp[aaddr + 1] * 256;
                if (addr == 0xD6CE)
                    continue; // Not a valid room
                byte[] room = DecodeRoom(addr, 12 * 8);
                for (int i = 0; i < room.Length; i++)
                {
                    if (room[i] > roommax)
                        roommax = room[i];
                }

                int daaddr = 0xDF27 + r * 2;
                int daddr = memdmp[daaddr] + memdmp[daaddr + 1] * 256;
                byte[] rdesc = DecodeRoom(daddr, 49);

                int xr = coords[r * 2] * colwid + 20;
                int yr = coords[r * 2 + 1] * rowhei + 20;

                DrawRoom(bmp, xr, yr, room, 0xE147, rdesc);
                g.DrawString($"{r}", font, Brushes.Navy, xr, yr - 12);

                int roomdown = rdesc[35];
                if (roomdown < 72)
                    g.DrawString($"{roomdown}", font, Brushes.Navy, xr + 3 * 8, yr + 7 * 8);
                int roomup = rdesc[36];
                if (roomup < 72)
                    g.DrawString($"{roomup}", font, Brushes.Navy, xr + 7 * 8, yr - 8);
                int roomleft = rdesc[37];
                if (roomleft < 72)
                    g.DrawString($"{roomleft}", font, Brushes.Navy, xr - 8, yr + 5 * 8);
                int roomright = rdesc[38];
                if (roomright < 72)
                    g.DrawString($"{roomright}", font, Brushes.Navy, xr + 11 * 8 + 2, yr + 1 * 8);
            }

            fileroomdescs.WriteLine();
            fileroomdescs.WriteLine($"room max byte: {roommax:X2}");
            fileroomdescs.WriteLine($"roomdescs max byte: {roomdescmax:X2}");
            fileroomdescs.Flush();
            Console.WriteLine("roomdescs.txt saved");

            var roomsfilename = "roomsmap.png";
            bmp.Save(roomsfilename);
            Console.WriteLine($"{roomsfilename} saved");
        }

        private static readonly byte[] RoomEtalon = new byte[96]
        {
            0x08, 0x13, 0x4F, 0x13, 0x13, 0x13, 0x13, 0x50, 0x51, 0x52, 0x13, 0x09,
            0x12, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x14,
            0x12, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x14,
            0x12, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x14,
            0x12, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x14,
            0x12, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x14,
            0x12, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x14,
            0x17, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x15, 0x08,
        };

        static void TestNewEncode()
        {
            byte[] savdmp = File.ReadAllBytes("memdmp.bin");
            Array.Copy(savdmp, 0, memdmp, 0, 65536);

            int encodedDescSumOld = 0, encodedDescSumNew = 0;
            int rdescRawSum = 0;
            for (int r = 0; r < 72; r++)
            {
                if (RoomsNotUsed.Contains(r))
                    continue;

                int daaddr = 0xDF27 + r * 2;
                int daddr = memdmp[daaddr] + memdmp[daaddr + 1] * 256;
                int rdescEncodedLength = GetRoomEncodedLength(daddr, 49);
                encodedDescSumOld += rdescEncodedLength;
                rdescRawSum += 49;
                byte[] rdesc = DecodeRoom(daddr, 49);

                byte[] rdescEncodedNew = EncodeRoomNew(rdesc);
                encodedDescSumNew += rdescEncodedNew.Length;

                //TODO: Check decode back
            }
            Console.WriteLine(
                $"Rdesc sums: raw {rdescRawSum}, old encoded: {encodedDescSumOld}, new encoded: {encodedDescSumNew}, " +
                $"old ratio: {(float)(encodedDescSumOld) / rdescRawSum}, " +
                $"new ratio: {(float)(encodedDescSumNew) / rdescRawSum}");

            List<int> roomAddrs = new List<int>();
            for (int r = 0; r < 72; r++)
            {
                if (RoomsNotUsed.Contains(r))
                    continue;
                int aaddr = 0xDE97 + r * 2;
                int addr = memdmp[aaddr] + memdmp[aaddr + 1] * 256;
                if (addr == 0xD6CE)
                    continue; // Not a valid room
                roomAddrs.Add(addr);
            }
            roomAddrs.Add(0xEB27);
            roomAddrs.Add(0xF329);
            roomAddrs.Add(0xF42F);
            roomAddrs.Add(0xF468);
            roomAddrs.Add(0xF4B5);
            roomAddrs.Add(0xF515);

            int encodedRoomSumOld = 0, encodedRoomSumNew = 0;
            int roomRawSum = 0;
            for (int r = 0; r < roomAddrs.Count; r++)
            {
                int addr = roomAddrs[r];

                int roomEncodedLength = GetRoomEncodedLength(addr, 12 * 8);
                encodedRoomSumOld += roomEncodedLength;
                roomRawSum += 12 * 8;
                byte[] room = DecodeRoom(addr, 12 * 8);
                
                // for regular rooms (not screens) mask all standard tiles
                if (addr < 0xD243)
                {
                    for (int i = 0; i < 96; i++)
                    {
                        if (room[i] == RoomEtalon[i])
                            room[i] = 0x7F;
                    }
                }

                byte[] romEncodedNew = EncodeRoomNew(room);
                encodedRoomSumNew += romEncodedNew.Length;

                //TODO: Check decode back
            }
            Console.WriteLine(
                $"Rooms sums: raw {roomRawSum}, old encoded: {encodedRoomSumOld}, new encoded: {encodedRoomSumNew}, " +
                $"old ratio: {(float)(encodedRoomSumOld) / roomRawSum}, " +
                $"new ratio: {(float)(encodedRoomSumNew) / roomRawSum}");

            int totalEncodedOld = encodedDescSumOld + encodedRoomSumOld;
            int totalEncodedNew = encodedDescSumNew + encodedRoomSumNew;
            Console.WriteLine(
                $"Raw length total:\t\t{rdescRawSum + roomRawSum}");
            Console.WriteLine(
                $"Old encoding length total:\t{totalEncodedOld}, " +
                $"ratio: {(float)(totalEncodedOld) / (rdescRawSum + roomRawSum)}");
            Console.WriteLine(
                $"New encoding length total:\t{totalEncodedNew}, " +
                $"ratio: {(float)totalEncodedNew / (rdescRawSum + roomRawSum)}");

            Console.WriteLine(
                $"Old-new encoding length bonus:\t{totalEncodedOld - totalEncodedNew}, " +
                $"ratio: {(float)(totalEncodedOld - totalEncodedNew) / (rdescRawSum + roomRawSum)}");
        }

        static byte[] DecodeRoom(int addr, int count)
        {
            byte[] room = new byte[count];
            int roomi = 0;
            while (roomi < count)
            {
                byte v = memdmp[addr++];
                if (v != 0xff)
                    room[roomi++] = v;
                else
                {
                    int c = memdmp[addr++];
                    v = memdmp[addr++];
                    for (int i = 0; i < c; i++)
                    {
                        room[roomi++] = v;
                    }
                }
            }

            return room;
        }

        static int GetRoomEncodedLength(int addr, int count)
        {
            int startAddr = addr;

            byte[] room = new byte[count];
            int roomi = 0;
            while (roomi < count)
            {
                byte v = memdmp[addr++];
                if (v != 0xff)
                    room[roomi++] = v;
                else
                {
                    int c = memdmp[addr++];
                    v = memdmp[addr++];
                    for (int i = 0; i < c; i++)
                    {
                        room[roomi++] = v;
                    }
                }
            }

            return addr - startAddr;
        }

        static byte[] EncodeRoomNew(byte[] room)
        {
            var result = new List<byte>();

            int roomi = 0;
            int repeat = 1;
            byte prev = (byte)(room[0] ^ 255);
            while (roomi < room.Length)
            {
                byte curr = room[roomi];
                roomi++;
                if (prev == curr)
                {
                    repeat++;
                    if (roomi < room.Length)
                        continue;
                }

                if (repeat > 63)
                    throw new Exception($"{nameof(EncodeRoomNew)} Repeat count too big: {repeat}");

                if (repeat == 1)
                    result.Add(prev);
                else if (repeat == 2)
                {
                    result.Add(prev);
                    result.Add(prev);
                }
                else  // repeat >= 3
                {
                    if (prev == 0x7F)
                    {
                        // Taking "repeat" bytes from room etalon
                        result.Add((byte)(256 - repeat));
                    }
                    else
                    {
                        result.Add((byte)(256 - 64 - repeat));
                        result.Add(prev);
                    }
                }

                repeat = 1;
                prev = curr;
            }

            return result.ToArray();
        }

        static void DrawRoom(Bitmap bmp, int xr, int yr, byte[] room, int tileaddr, byte[] rdesc = null)
        {
            for (int row = 0; row < 8; row++)
            {
                for (int col = 0; col < 12; col++)
                {
                    var tile = room[col + row * 12];
                    int x = col * 8 + xr;
                    int y = row * 8 + yr;

                    var taddr = tileaddr + tile * 16;
                    for (int s = 0; s < 8; s++)
                    {
                        var val1 = memdmp[taddr];
                        var val2 = memdmp[taddr + 8];
                        for (int b = 0; b < 8; b++)
                        {
                            int v1 = (val1 << b) & 128;
                            int v2 = (val2 << b) & 128;
                            int v = (v1 >> 7) | (v2 >> 6);
                            Color c = colorsY[v];
                            bmp.SetPixel(x + b, y, c);
                        }

                        taddr++;
                        y++;
                    }
                }
            }

            if (rdesc != null)
            {
                Graphics g = Graphics.FromImage(bmp);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
                //var font = new Font("Tahoma", 7);
                var pen = new Pen(Color.Coral, 1);

                for (int i = 0; i < rdesc.Length; i++)
                {
                    var b = rdesc[i];
                    if (b < 36 || b > 84)
                        continue;

                    int doffset = -1;
                    switch (i)
                    {
                        case 0: case 1:
                            doffset = 2;
                            break;
                        case 3: case 4:
                            doffset = 5;
                            break;
                        case 6: case 7:
                            doffset = 8;
                            break;
                        case 11: case 12:
                            doffset = 13;
                            break;
                        case 15: case 16:
                            doffset = 17;
                            break;
                        case 25: case 26:
                            doffset = 27;
                            break;
                        case 32: case 33:
                            doffset = 34;
                            break;
                    }

                    int row = b / 12;
                    int col = b % 12;
                    int x = col * 8 + xr;
                    int y = row * 8 + yr;

                    if (doffset < 0)
                        g.DrawRectangle(pen, x + 1, y + 1, 7, 7);
                    else
                    {
                        var d = rdesc[doffset];
                        switch (d)
                        {
                            case 0:  // down
                                g.DrawLine(pen, x + 4, y + 1, x + 4, y + 8);
                                g.DrawLine(pen, x + 4, y + 8, x + 0, y + 4);
                                g.DrawLine(pen, x + 4, y + 8, x + 8, y + 4);
                                break;
                            case 1:  // up
                                g.DrawLine(pen, x + 4, y + 1, x + 4, y + 8);
                                g.DrawLine(pen, x + 4, y + 1, x + 0, y + 5);
                                g.DrawLine(pen, x + 4, y + 1, x + 8, y + 5);
                                break;
                            case 2:  // left
                                g.DrawLine(pen, x + 1, y + 4, x + 8, y + 4);
                                g.DrawLine(pen, x + 0, y + 4, x + 4, y + 0);
                                g.DrawLine(pen, x + 0, y + 4, x + 4, y + 8);
                                break;
                            case 3:  // right
                                g.DrawLine(pen, x + 1, y + 4, x + 8, y + 4);
                                g.DrawLine(pen, x + 8, y + 4, x + 4, y + 0);
                                g.DrawLine(pen, x + 8, y + 4, x + 4, y + 8);
                                break;
                        }
                    }
                }
            }
        }

        static void DrawRoomNewTiles(Graphics g, int xr, int yr, byte[] room, Bitmap bmpTiles)
        {
            for (int row = 0; row < 8; row++)
            {
                for (int col = 0; col < 12; col++)
                {
                    var tile = room[col + row * 12];
                    int x = col * 16 + xr;
                    int y = row * 16 + yr;

                    var tilex = 8 + (tile / 16) * 20;
                    var tiley = 8 + (tile % 16) * 20;

                    g.DrawImage(bmpTiles, x, y, new Rectangle(tilex, tiley, 16, 16), GraphicsUnit.Pixel);
                }
            }
        }

        static void PrepareCreditsMargins()
        {
            var file = new StreamWriter("credits.txt");

            for (int addr = 0xDDF2; addr < 0xDE47; addr++)
            {
                if ((addr - 0xDDF2) % 16 == 0)
                    file.Write("  DEFB ");
                var value = memdmp[addr] * 2;
                file.Write($"${value:X2}");
                if ((addr - 0xDDF2) % 16 == 15)
                    file.WriteLine();
                else
                    file.Write(",");
            }

            file.Flush();
            Console.WriteLine("credits.txt saved");
        }
    }
}
