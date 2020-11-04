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
            Color.FromArgb(255, 120,120,120),
            Color.FromArgb(255, 180,180,180),
            Color.Black
        };
        private static readonly Color[] colorsB = new Color[]
        {
            Color.PowderBlue,
            Color.FromArgb(255, 120,120,120),
            Color.FromArgb(255, 180,180,180),
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

            //DumpChangedAreas();
            //DumpArchivedStrings();
            //PrepareArchivedStrings();
            //PrepareLineAddresses();
            //PrepareFontProto();
            PrepareTilesetMasked();
            PrepareTileset3();
        }

        static void ParseMemoryDump()
        {
            string textdump = File.ReadAllText("desolatemenu.txt");
            var lines = textdump.Split(new[] { Environment.NewLine }, StringSplitOptions.None);
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
            using (var writer = new StreamWriter("fontproto.txt"))
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

                            octets[i] = (byte)val;
                        }

                        bool lowered = octets[10] != 0;
                        byte mask = 0;
                        for (int i = 0; i < 11; i++)
                            mask |= octets[i];
                        if (mask == 0)
                            continue;  // Skip empty symbol

                        int width = 0;
                        for (int b = 0; b < 8; b++)
                        {
                            if (((mask >> (7 - b)) & 1) == 1)
                                width = b + 1;
                        }

                        byte descbyte = (byte)((lowered ? 128 : 0) + width);

                        writer.Write($"  DB ${descbyte:X2}, ");
                        var start = lowered ? 1 : 0;
                        for (int i = start; i < start + 10; i++)
                        {
                            writer.Write($"${octets[i]:X2}");
                            if (i < start + 9) writer.Write(",");
                        }

                        var ch = (char)(' ' + col + row * 16);
                        writer.Write($"  ; {ch}");
                        writer.WriteLine();
                    }
                }
                Console.WriteLine("fontproto.txt saved");
            }
        }

        static void PrepareTilesetMasked()
        {
            Bitmap bmp = new Bitmap(@"..\tiles.png");

            using (var writer = new StreamWriter("desoltil1.asm"))
            {
                writer.WriteLine("; Tileset 1, 157 tiles 16x8 with mask");
                writer.WriteLine("Tileset1:");
                PrepareTilesetMaskedImpl(bmp, 8, 157, writer);
                Console.WriteLine("desoltil1.asm saved");
            }

            using (var writer = new StreamWriter("desoltil2.asm"))
            {
                writer.WriteLine("; Tileset 2, 127 tiles 16x8 with mask");
                writer.WriteLine("Tileset2:");
                PrepareTilesetMaskedImpl(bmp, 212, 127, writer);
                Console.WriteLine("desoltil2.asm saved");
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

        static void PrepareTileset3()
        {
            using (var writer = new StreamWriter("tileset3.asm"))
            {
                Bitmap bmp = new Bitmap(@"..\tiles.png");

                writer.WriteLine("; Tiles inventory items, 14 tiles 16x16");
                writer.WriteLine("Tileset3:");
                for (int tile = 0; tile < 16; tile++)
                {
                    var words = new int[16];
                    int x = 376;
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
            Console.WriteLine("tileset3.asm saved");
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
                        sb.Append((char)v);
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
                var eaddr = 0xE09B;  // address in the memory dump
                while (eaddr < 0xE147)
                {
                    var offset = memdmp[eaddr] + memdmp[eaddr + 1] * 256;
                    sb.Clear();
                    for (; ; )
                    {
                        var v = desdata[offset + 0x48];
                        if (v == 0)
                            break;
                        sb.Append((char)v);
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
            ProcessTiles8x8x4(bmp, 978, 42 + 32 * 8, 0xE147, 0xEB27);  // Tileset 1
            ProcessTiles8x8x4(bmp, 1080, 42 + 32 * 8, 0xEB39, 0xF329);  // Tileset 2
            ProcessTiles8x8x4(bmp, 1162, 42 + 32 * 8, 0xF34F, 0xF34F+0xE0);
            ProcessScreen(bmp, 6 + 180, 42 + 32 * 8, 0x9340, 0x9872);
            ProcessScreen(bmp, 6 + 310, 42 + 32 * 8, 0xA28F, 0xA58F);
            ProcessSavRoom(bmp, 6 + 310, 42 + 32 * 8 + 70, 0xE147);  // Room in Tileset 1
            ProcessSavRoom(bmp, 6 + 410, 42 + 32 * 8 + 70, 0xEB39);  // Room in Tileset 2
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
            int addr = 0xDBF5;  // Здесь комната в тайлах
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

            int addr, xr, yr, roomlen;
            for (int r = 0; r < 72; r++)
            {
                int aaddr = 0xDE97 + r * 2;  // Здесь адреса закодированных комнат
                addr = memdmp[aaddr] + memdmp[aaddr + 1] * 256;
                if (addr == 0xD6CE)
                    continue;  // Not a valid room

                xr = x0 + (r / 6) * 106;
                yr = y0 + (r % 6) * 74 + 6;

                roomlen = DrawRoom(bmp, xr, yr, addr, 0xE147);

                g.DrawString($"{r}: {addr:X4}", font, Brushes.Navy, xr, yr - 12);

                filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room #{r}");
            }

            addr = 0xEB27;
            xr = x0 + 12 * 106;
            yr = y0 + 0 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF329;
            xr = x0 + 12 * 106;
            yr = y0 + 1 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF42F;
            xr = x0 + 12 * 106;
            yr = y0 + 2 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF468;
            xr = x0 + 12 * 106;
            yr = y0 + 3 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF4B5;
            xr = x0 + 12 * 106;
            yr = y0 + 4 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xEB39);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

            addr = 0xF515;
            xr = x0 + 12 * 106;
            yr = y0 + 5 * 74 + 6;
            roomlen = DrawRoom(bmp, xr, yr, addr, 0xE147);
            g.DrawString($"{addr:X4}", font, Brushes.Navy, xr, yr - 12);
            filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room");

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

                roomlen = addrnext - addr;

                filerooms.WriteLine($"B ${addr:X4},{roomlen},16 Room #{r} desc");
            }

            filerooms.Flush();

            var roomsfilename = "rooms.png";
            bmp.Save(roomsfilename);
            Console.WriteLine($"{roomsfilename} saved");
        }

        static int DrawRoom(Bitmap bmp, int xr, int yr, int addr, int tileaddr)
        {
            byte[] room = new byte[12 * 8];
            int roomi = 0;
            int startaddr = addr;
            while (roomi < 12 * 8)
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

            return addr - startaddr;
        }
    }
}
