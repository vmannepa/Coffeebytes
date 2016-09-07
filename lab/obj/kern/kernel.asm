
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	//movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100025:	b8 2c 00 10 f0       	mov    $0xf010002c,%eax
	jmp	*%eax
f010002a:	ff e0                	jmp    *%eax

f010002c <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002c:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100031:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100036:	e8 5f 00 00 00       	call   f010009a <i386_init>

f010003b <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003b:	eb fe                	jmp    f010003b <spin>

f010003d <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f010003d:	55                   	push   %ebp
f010003e:	89 e5                	mov    %esp,%ebp
f0100040:	53                   	push   %ebx
f0100041:	83 ec 14             	sub    $0x14,%esp
f0100044:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f0100047:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004b:	c7 04 24 20 19 10 f0 	movl   $0xf0101920,(%esp)
f0100052:	e8 ca 08 00 00       	call   f0100921 <cprintf>
	if (x > 0)
f0100057:	85 db                	test   %ebx,%ebx
f0100059:	7e 0d                	jle    f0100068 <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005b:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010005e:	89 04 24             	mov    %eax,(%esp)
f0100061:	e8 d7 ff ff ff       	call   f010003d <test_backtrace>
f0100066:	eb 1c                	jmp    f0100084 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f0100068:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010006f:	00 
f0100070:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100077:	00 
f0100078:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010007f:	e8 0b 07 00 00       	call   f010078f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100084:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100088:	c7 04 24 3c 19 10 f0 	movl   $0xf010193c,(%esp)
f010008f:	e8 8d 08 00 00       	call   f0100921 <cprintf>
}
f0100094:	83 c4 14             	add    $0x14,%esp
f0100097:	5b                   	pop    %ebx
f0100098:	5d                   	pop    %ebp
f0100099:	c3                   	ret    

f010009a <i386_init>:

void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a0:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a5:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b5:	00 
f01000b6:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000bd:	e8 b5 13 00 00       	call   f0101477 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c2:	e8 98 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000c7:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000ce:	00 
f01000cf:	c7 04 24 57 19 10 f0 	movl   $0xf0101957,(%esp)
f01000d6:	e8 46 08 00 00       	call   f0100921 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000db:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e2:	e8 56 ff ff ff       	call   f010003d <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ee:	e8 a6 06 00 00       	call   f0100799 <monitor>
f01000f3:	eb f2                	jmp    f01000e7 <i386_init+0x4d>

f01000f5 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f5:	55                   	push   %ebp
f01000f6:	89 e5                	mov    %esp,%ebp
f01000f8:	56                   	push   %esi
f01000f9:	53                   	push   %ebx
f01000fa:	83 ec 10             	sub    $0x10,%esp
f01000fd:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100100:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f0100107:	75 3d                	jne    f0100146 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100109:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010010f:	fa                   	cli    
f0100110:	fc                   	cld    

	va_start(ap, fmt);
f0100111:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100114:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100117:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011b:	8b 45 08             	mov    0x8(%ebp),%eax
f010011e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100122:	c7 04 24 72 19 10 f0 	movl   $0xf0101972,(%esp)
f0100129:	e8 f3 07 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f010012e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100132:	89 34 24             	mov    %esi,(%esp)
f0100135:	e8 b4 07 00 00       	call   f01008ee <vcprintf>
	cprintf("\n");
f010013a:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100141:	e8 db 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100146:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014d:	e8 47 06 00 00       	call   f0100799 <monitor>
f0100152:	eb f2                	jmp    f0100146 <_panic+0x51>

f0100154 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100154:	55                   	push   %ebp
f0100155:	89 e5                	mov    %esp,%ebp
f0100157:	53                   	push   %ebx
f0100158:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015b:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010015e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100161:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100165:	8b 45 08             	mov    0x8(%ebp),%eax
f0100168:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016c:	c7 04 24 8a 19 10 f0 	movl   $0xf010198a,(%esp)
f0100173:	e8 a9 07 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f0100178:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017c:	8b 45 10             	mov    0x10(%ebp),%eax
f010017f:	89 04 24             	mov    %eax,(%esp)
f0100182:	e8 67 07 00 00       	call   f01008ee <vcprintf>
	cprintf("\n");
f0100187:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f010018e:	e8 8e 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);
}
f0100193:	83 c4 14             	add    $0x14,%esp
f0100196:	5b                   	pop    %ebx
f0100197:	5d                   	pop    %ebp
f0100198:	c3                   	ret    
f0100199:	66 90                	xchg   %ax,%ax
f010019b:	66 90                	xchg   %ax,%ax
f010019d:	66 90                	xchg   %ax,%ax
f010019f:	90                   	nop

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 00 1a 10 f0 	movzbl -0xfefe600(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d e0 19 10 f0 	mov    -0xfefe620(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 a4 19 10 f0 	movl   $0xf01019a4,(%esp)
f01002e9:	e8 33 06 00 00       	call   f0100921 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 36 10 00 00       	call   f01014c4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 b0 19 10 f0 	movl   $0xf01019b0,(%esp)
f0100644:	e8 d8 02 00 00       	call   f0100921 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 00 1c 10 	movl   $0xf0101c00,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 1e 1c 10 	movl   $0xf0101c1e,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 23 1c 10 f0 	movl   $0xf0101c23,(%esp)
f010069d:	e8 7f 02 00 00       	call   f0100921 <cprintf>
f01006a2:	c7 44 24 08 8c 1c 10 	movl   $0xf0101c8c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 2c 1c 10 	movl   $0xf0101c2c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 23 1c 10 f0 	movl   $0xf0101c23,(%esp)
f01006b9:	e8 63 02 00 00       	call   f0100921 <cprintf>
	return 0;
}
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	c9                   	leave  
f01006c4:	c3                   	ret    

f01006c5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cb:	c7 04 24 35 1c 10 f0 	movl   $0xf0101c35,(%esp)
f01006d2:	e8 4a 02 00 00       	call   f0100921 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006de:	00 
f01006df:	c7 04 24 b4 1c 10 f0 	movl   $0xf0101cb4,(%esp)
f01006e6:	e8 36 02 00 00       	call   f0100921 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006eb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006f2:	00 
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006fa:	f0 
f01006fb:	c7 04 24 dc 1c 10 f0 	movl   $0xf0101cdc,(%esp)
f0100702:	e8 1a 02 00 00       	call   f0100921 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100707:	c7 44 24 08 07 19 10 	movl   $0x101907,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 07 19 10 	movl   $0xf0101907,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f010071e:	e8 fe 01 00 00       	call   f0100921 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100723:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 24 1d 10 f0 	movl   $0xf0101d24,(%esp)
f010073a:	e8 e2 01 00 00       	call   f0100921 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 48 1d 10 f0 	movl   $0xf0101d48,(%esp)
f0100756:	e8 c6 01 00 00       	call   f0100921 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010075b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100760:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100765:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100770:	85 c0                	test   %eax,%eax
f0100772:	0f 48 c2             	cmovs  %edx,%eax
f0100775:	c1 f8 0a             	sar    $0xa,%eax
f0100778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077c:	c7 04 24 6c 1d 10 f0 	movl   $0xf0101d6c,(%esp)
f0100783:	e8 99 01 00 00       	call   f0100921 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100792:	b8 00 00 00 00       	mov    $0x0,%eax
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	57                   	push   %edi
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a2:	c7 04 24 98 1d 10 f0 	movl   $0xf0101d98,(%esp)
f01007a9:	e8 73 01 00 00       	call   f0100921 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ae:	c7 04 24 bc 1d 10 f0 	movl   $0xf0101dbc,(%esp)
f01007b5:	e8 67 01 00 00       	call   f0100921 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007ba:	c7 04 24 4e 1c 10 f0 	movl   $0xf0101c4e,(%esp)
f01007c1:	e8 5a 0a 00 00       	call   f0101220 <readline>
f01007c6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	74 ee                	je     f01007ba <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d3:	be 00 00 00 00       	mov    $0x0,%esi
f01007d8:	eb 0a                	jmp    f01007e4 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007da:	c6 03 00             	movb   $0x0,(%ebx)
f01007dd:	89 f7                	mov    %esi,%edi
f01007df:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e4:	0f b6 03             	movzbl (%ebx),%eax
f01007e7:	84 c0                	test   %al,%al
f01007e9:	74 63                	je     f010084e <monitor+0xb5>
f01007eb:	0f be c0             	movsbl %al,%eax
f01007ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f2:	c7 04 24 52 1c 10 f0 	movl   $0xf0101c52,(%esp)
f01007f9:	e8 3c 0c 00 00       	call   f010143a <strchr>
f01007fe:	85 c0                	test   %eax,%eax
f0100800:	75 d8                	jne    f01007da <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100802:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100805:	74 47                	je     f010084e <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100807:	83 fe 0f             	cmp    $0xf,%esi
f010080a:	75 16                	jne    f0100822 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010080c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100813:	00 
f0100814:	c7 04 24 57 1c 10 f0 	movl   $0xf0101c57,(%esp)
f010081b:	e8 01 01 00 00       	call   f0100921 <cprintf>
f0100820:	eb 98                	jmp    f01007ba <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100822:	8d 7e 01             	lea    0x1(%esi),%edi
f0100825:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100829:	eb 03                	jmp    f010082e <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082e:	0f b6 03             	movzbl (%ebx),%eax
f0100831:	84 c0                	test   %al,%al
f0100833:	74 ad                	je     f01007e2 <monitor+0x49>
f0100835:	0f be c0             	movsbl %al,%eax
f0100838:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083c:	c7 04 24 52 1c 10 f0 	movl   $0xf0101c52,(%esp)
f0100843:	e8 f2 0b 00 00       	call   f010143a <strchr>
f0100848:	85 c0                	test   %eax,%eax
f010084a:	74 df                	je     f010082b <monitor+0x92>
f010084c:	eb 94                	jmp    f01007e2 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010084e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100855:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100856:	85 f6                	test   %esi,%esi
f0100858:	0f 84 5c ff ff ff    	je     f01007ba <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085e:	c7 44 24 04 1e 1c 10 	movl   $0xf0101c1e,0x4(%esp)
f0100865:	f0 
f0100866:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100869:	89 04 24             	mov    %eax,(%esp)
f010086c:	e8 6b 0b 00 00       	call   f01013dc <strcmp>
f0100871:	85 c0                	test   %eax,%eax
f0100873:	74 1b                	je     f0100890 <monitor+0xf7>
f0100875:	c7 44 24 04 2c 1c 10 	movl   $0xf0101c2c,0x4(%esp)
f010087c:	f0 
f010087d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100880:	89 04 24             	mov    %eax,(%esp)
f0100883:	e8 54 0b 00 00       	call   f01013dc <strcmp>
f0100888:	85 c0                	test   %eax,%eax
f010088a:	75 2f                	jne    f01008bb <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010088c:	b0 01                	mov    $0x1,%al
f010088e:	eb 05                	jmp    f0100895 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100890:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100895:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100898:	01 d0                	add    %edx,%eax
f010089a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010089d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008a1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008a4:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008a8:	89 34 24             	mov    %esi,(%esp)
f01008ab:	ff 14 85 ec 1d 10 f0 	call   *-0xfefe214(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	78 1d                	js     f01008d3 <monitor+0x13a>
f01008b6:	e9 ff fe ff ff       	jmp    f01007ba <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008bb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c2:	c7 04 24 74 1c 10 f0 	movl   $0xf0101c74,(%esp)
f01008c9:	e8 53 00 00 00       	call   f0100921 <cprintf>
f01008ce:	e9 e7 fe ff ff       	jmp    f01007ba <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d3:	83 c4 5c             	add    $0x5c,%esp
f01008d6:	5b                   	pop    %ebx
f01008d7:	5e                   	pop    %esi
f01008d8:	5f                   	pop    %edi
f01008d9:	5d                   	pop    %ebp
f01008da:	c3                   	ret    

f01008db <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
f01008de:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01008e4:	89 04 24             	mov    %eax,(%esp)
f01008e7:	e8 65 fd ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01008ec:	c9                   	leave  
f01008ed:	c3                   	ret    

f01008ee <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008ee:	55                   	push   %ebp
f01008ef:	89 e5                	mov    %esp,%ebp
f01008f1:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008fb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100902:	8b 45 08             	mov    0x8(%ebp),%eax
f0100905:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100909:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100910:	c7 04 24 db 08 10 f0 	movl   $0xf01008db,(%esp)
f0100917:	e8 18 04 00 00       	call   f0100d34 <vprintfmt>
	return cnt;
}
f010091c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010091f:	c9                   	leave  
f0100920:	c3                   	ret    

f0100921 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100921:	55                   	push   %ebp
f0100922:	89 e5                	mov    %esp,%ebp
f0100924:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100927:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010092a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 b5 ff ff ff       	call   f01008ee <vcprintf>
	va_end(ap);

	return cnt;
}
f0100939:	c9                   	leave  
f010093a:	c3                   	ret    

f010093b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010093b:	55                   	push   %ebp
f010093c:	89 e5                	mov    %esp,%ebp
f010093e:	57                   	push   %edi
f010093f:	56                   	push   %esi
f0100940:	53                   	push   %ebx
f0100941:	83 ec 10             	sub    $0x10,%esp
f0100944:	89 c6                	mov    %eax,%esi
f0100946:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100949:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010094c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010094f:	8b 1a                	mov    (%edx),%ebx
f0100951:	8b 01                	mov    (%ecx),%eax
f0100953:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100956:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010095d:	eb 77                	jmp    f01009d6 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010095f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100962:	01 d8                	add    %ebx,%eax
f0100964:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100969:	99                   	cltd   
f010096a:	f7 f9                	idiv   %ecx
f010096c:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010096e:	eb 01                	jmp    f0100971 <stab_binsearch+0x36>
			m--;
f0100970:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100971:	39 d9                	cmp    %ebx,%ecx
f0100973:	7c 1d                	jl     f0100992 <stab_binsearch+0x57>
f0100975:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100978:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010097d:	39 fa                	cmp    %edi,%edx
f010097f:	75 ef                	jne    f0100970 <stab_binsearch+0x35>
f0100981:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100984:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100987:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f010098b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010098e:	73 18                	jae    f01009a8 <stab_binsearch+0x6d>
f0100990:	eb 05                	jmp    f0100997 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100992:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100995:	eb 3f                	jmp    f01009d6 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100997:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010099a:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f010099c:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010099f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009a6:	eb 2e                	jmp    f01009d6 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009a8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ab:	73 15                	jae    f01009c2 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009b0:	48                   	dec    %eax
f01009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009b4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009b7:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009c0:	eb 14                	jmp    f01009d6 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009c2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009c5:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009c8:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009ca:	ff 45 0c             	incl   0xc(%ebp)
f01009cd:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009cf:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009d6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009d9:	7e 84                	jle    f010095f <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009db:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009df:	75 0d                	jne    f01009ee <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009e4:	8b 00                	mov    (%eax),%eax
f01009e6:	48                   	dec    %eax
f01009e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009ea:	89 07                	mov    %eax,(%edi)
f01009ec:	eb 22                	jmp    f0100a10 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009f3:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009f6:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f8:	eb 01                	jmp    f01009fb <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009fa:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009fb:	39 c1                	cmp    %eax,%ecx
f01009fd:	7d 0c                	jge    f0100a0b <stab_binsearch+0xd0>
f01009ff:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a02:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a07:	39 fa                	cmp    %edi,%edx
f0100a09:	75 ef                	jne    f01009fa <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a0b:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a0e:	89 07                	mov    %eax,(%edi)
	}
}
f0100a10:	83 c4 10             	add    $0x10,%esp
f0100a13:	5b                   	pop    %ebx
f0100a14:	5e                   	pop    %esi
f0100a15:	5f                   	pop    %edi
f0100a16:	5d                   	pop    %ebp
f0100a17:	c3                   	ret    

f0100a18 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
f0100a1b:	57                   	push   %edi
f0100a1c:	56                   	push   %esi
f0100a1d:	53                   	push   %ebx
f0100a1e:	83 ec 2c             	sub    $0x2c,%esp
f0100a21:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a24:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a27:	c7 03 fc 1d 10 f0    	movl   $0xf0101dfc,(%ebx)
	info->eip_line = 0;
f0100a2d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a34:	c7 43 08 fc 1d 10 f0 	movl   $0xf0101dfc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a3b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a42:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a45:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a4c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a52:	76 12                	jbe    f0100a66 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a54:	b8 6e 71 10 f0       	mov    $0xf010716e,%eax
f0100a59:	3d b5 58 10 f0       	cmp    $0xf01058b5,%eax
f0100a5e:	0f 86 6b 01 00 00    	jbe    f0100bcf <debuginfo_eip+0x1b7>
f0100a64:	eb 1c                	jmp    f0100a82 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a66:	c7 44 24 08 06 1e 10 	movl   $0xf0101e06,0x8(%esp)
f0100a6d:	f0 
f0100a6e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a75:	00 
f0100a76:	c7 04 24 13 1e 10 f0 	movl   $0xf0101e13,(%esp)
f0100a7d:	e8 73 f6 ff ff       	call   f01000f5 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a82:	80 3d 6d 71 10 f0 00 	cmpb   $0x0,0xf010716d
f0100a89:	0f 85 47 01 00 00    	jne    f0100bd6 <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a8f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a96:	b8 b4 58 10 f0       	mov    $0xf01058b4,%eax
f0100a9b:	2d 50 20 10 f0       	sub    $0xf0102050,%eax
f0100aa0:	c1 f8 02             	sar    $0x2,%eax
f0100aa3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100aa9:	83 e8 01             	sub    $0x1,%eax
f0100aac:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100aaf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ab3:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100aba:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100abd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ac0:	b8 50 20 10 f0       	mov    $0xf0102050,%eax
f0100ac5:	e8 71 fe ff ff       	call   f010093b <stab_binsearch>
	if (lfile == 0)
f0100aca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100acd:	85 c0                	test   %eax,%eax
f0100acf:	0f 84 08 01 00 00    	je     f0100bdd <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ad5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ad8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100adb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ade:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ae2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ae9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aec:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aef:	b8 50 20 10 f0       	mov    $0xf0102050,%eax
f0100af4:	e8 42 fe ff ff       	call   f010093b <stab_binsearch>

	if (lfun <= rfun) {
f0100af9:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100afc:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100aff:	7f 2e                	jg     f0100b2f <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b01:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b04:	8d 90 50 20 10 f0    	lea    -0xfefdfb0(%eax),%edx
f0100b0a:	8b 80 50 20 10 f0    	mov    -0xfefdfb0(%eax),%eax
f0100b10:	b9 6e 71 10 f0       	mov    $0xf010716e,%ecx
f0100b15:	81 e9 b5 58 10 f0    	sub    $0xf01058b5,%ecx
f0100b1b:	39 c8                	cmp    %ecx,%eax
f0100b1d:	73 08                	jae    f0100b27 <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b1f:	05 b5 58 10 f0       	add    $0xf01058b5,%eax
f0100b24:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b27:	8b 42 08             	mov    0x8(%edx),%eax
f0100b2a:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b2d:	eb 06                	jmp    f0100b35 <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b2f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b35:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b3c:	00 
f0100b3d:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b40:	89 04 24             	mov    %eax,(%esp)
f0100b43:	e8 13 09 00 00       	call   f010145b <strfind>
f0100b48:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b4b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b4e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b51:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b54:	05 50 20 10 f0       	add    $0xf0102050,%eax
f0100b59:	eb 06                	jmp    f0100b61 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b5b:	83 ef 01             	sub    $0x1,%edi
f0100b5e:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b61:	39 cf                	cmp    %ecx,%edi
f0100b63:	7c 33                	jl     f0100b98 <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100b65:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b69:	80 fa 84             	cmp    $0x84,%dl
f0100b6c:	74 0b                	je     f0100b79 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b6e:	80 fa 64             	cmp    $0x64,%dl
f0100b71:	75 e8                	jne    f0100b5b <debuginfo_eip+0x143>
f0100b73:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b77:	74 e2                	je     f0100b5b <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b79:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b7c:	8b 87 50 20 10 f0    	mov    -0xfefdfb0(%edi),%eax
f0100b82:	ba 6e 71 10 f0       	mov    $0xf010716e,%edx
f0100b87:	81 ea b5 58 10 f0    	sub    $0xf01058b5,%edx
f0100b8d:	39 d0                	cmp    %edx,%eax
f0100b8f:	73 07                	jae    f0100b98 <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b91:	05 b5 58 10 f0       	add    $0xf01058b5,%eax
f0100b96:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b98:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100b9b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b9e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ba3:	39 f1                	cmp    %esi,%ecx
f0100ba5:	7d 42                	jge    f0100be9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100ba7:	8d 51 01             	lea    0x1(%ecx),%edx
f0100baa:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bad:	05 50 20 10 f0       	add    $0xf0102050,%eax
f0100bb2:	eb 07                	jmp    f0100bbb <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bb4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bb8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bbb:	39 f2                	cmp    %esi,%edx
f0100bbd:	74 25                	je     f0100be4 <debuginfo_eip+0x1cc>
f0100bbf:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bc2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bc6:	74 ec                	je     f0100bb4 <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bcd:	eb 1a                	jmp    f0100be9 <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bcf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bd4:	eb 13                	jmp    f0100be9 <debuginfo_eip+0x1d1>
f0100bd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bdb:	eb 0c                	jmp    f0100be9 <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be2:	eb 05                	jmp    f0100be9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100be4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100be9:	83 c4 2c             	add    $0x2c,%esp
f0100bec:	5b                   	pop    %ebx
f0100bed:	5e                   	pop    %esi
f0100bee:	5f                   	pop    %edi
f0100bef:	5d                   	pop    %ebp
f0100bf0:	c3                   	ret    
f0100bf1:	66 90                	xchg   %ax,%ax
f0100bf3:	66 90                	xchg   %ax,%ax
f0100bf5:	66 90                	xchg   %ax,%ax
f0100bf7:	66 90                	xchg   %ax,%ax
f0100bf9:	66 90                	xchg   %ax,%ax
f0100bfb:	66 90                	xchg   %ax,%ax
f0100bfd:	66 90                	xchg   %ax,%ax
f0100bff:	90                   	nop

f0100c00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c00:	55                   	push   %ebp
f0100c01:	89 e5                	mov    %esp,%ebp
f0100c03:	57                   	push   %edi
f0100c04:	56                   	push   %esi
f0100c05:	53                   	push   %ebx
f0100c06:	83 ec 3c             	sub    $0x3c,%esp
f0100c09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c0c:	89 d7                	mov    %edx,%edi
f0100c0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c11:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c17:	89 c3                	mov    %eax,%ebx
f0100c19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c1c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c1f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c22:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c2a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c2d:	39 d9                	cmp    %ebx,%ecx
f0100c2f:	72 05                	jb     f0100c36 <printnum+0x36>
f0100c31:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c34:	77 69                	ja     f0100c9f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c36:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c3d:	83 ee 01             	sub    $0x1,%esi
f0100c40:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c44:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c48:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c4c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c50:	89 c3                	mov    %eax,%ebx
f0100c52:	89 d6                	mov    %edx,%esi
f0100c54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c5a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c5e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c65:	89 04 24             	mov    %eax,(%esp)
f0100c68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c6b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c6f:	e8 0c 0a 00 00       	call   f0101680 <__udivdi3>
f0100c74:	89 d9                	mov    %ebx,%ecx
f0100c76:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c7a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c7e:	89 04 24             	mov    %eax,(%esp)
f0100c81:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c85:	89 fa                	mov    %edi,%edx
f0100c87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c8a:	e8 71 ff ff ff       	call   f0100c00 <printnum>
f0100c8f:	eb 1b                	jmp    f0100cac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c95:	8b 45 18             	mov    0x18(%ebp),%eax
f0100c98:	89 04 24             	mov    %eax,(%esp)
f0100c9b:	ff d3                	call   *%ebx
f0100c9d:	eb 03                	jmp    f0100ca2 <printnum+0xa2>
f0100c9f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ca2:	83 ee 01             	sub    $0x1,%esi
f0100ca5:	85 f6                	test   %esi,%esi
f0100ca7:	7f e8                	jg     f0100c91 <printnum+0x91>
f0100ca9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cb0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cb4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cb7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cba:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc5:	89 04 24             	mov    %eax,(%esp)
f0100cc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ccb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ccf:	e8 dc 0a 00 00       	call   f01017b0 <__umoddi3>
f0100cd4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cd8:	0f be 80 21 1e 10 f0 	movsbl -0xfefe1df(%eax),%eax
f0100cdf:	89 04 24             	mov    %eax,(%esp)
f0100ce2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce5:	ff d0                	call   *%eax
}
f0100ce7:	83 c4 3c             	add    $0x3c,%esp
f0100cea:	5b                   	pop    %ebx
f0100ceb:	5e                   	pop    %esi
f0100cec:	5f                   	pop    %edi
f0100ced:	5d                   	pop    %ebp
f0100cee:	c3                   	ret    

f0100cef <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cef:	55                   	push   %ebp
f0100cf0:	89 e5                	mov    %esp,%ebp
f0100cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cf5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cf9:	8b 10                	mov    (%eax),%edx
f0100cfb:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cfe:	73 0a                	jae    f0100d0a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d00:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d03:	89 08                	mov    %ecx,(%eax)
f0100d05:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d08:	88 02                	mov    %al,(%edx)
}
f0100d0a:	5d                   	pop    %ebp
f0100d0b:	c3                   	ret    

f0100d0c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d0c:	55                   	push   %ebp
f0100d0d:	89 e5                	mov    %esp,%ebp
f0100d0f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d12:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d15:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d19:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d1c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d20:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d27:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d2a:	89 04 24             	mov    %eax,(%esp)
f0100d2d:	e8 02 00 00 00       	call   f0100d34 <vprintfmt>
	va_end(ap);
}
f0100d32:	c9                   	leave  
f0100d33:	c3                   	ret    

f0100d34 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d34:	55                   	push   %ebp
f0100d35:	89 e5                	mov    %esp,%ebp
f0100d37:	57                   	push   %edi
f0100d38:	56                   	push   %esi
f0100d39:	53                   	push   %ebx
f0100d3a:	83 ec 3c             	sub    $0x3c,%esp
f0100d3d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d40:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d43:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d46:	eb 11                	jmp    f0100d59 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d48:	85 c0                	test   %eax,%eax
f0100d4a:	0f 84 48 04 00 00    	je     f0101198 <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f0100d50:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d54:	89 04 24             	mov    %eax,(%esp)
f0100d57:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d59:	83 c7 01             	add    $0x1,%edi
f0100d5c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d60:	83 f8 25             	cmp    $0x25,%eax
f0100d63:	75 e3                	jne    f0100d48 <vprintfmt+0x14>
f0100d65:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d69:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d70:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d77:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d7e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d83:	eb 1f                	jmp    f0100da4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d85:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d88:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100d8c:	eb 16                	jmp    f0100da4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d91:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d95:	eb 0d                	jmp    f0100da4 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100d97:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d9d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100da4:	8d 47 01             	lea    0x1(%edi),%eax
f0100da7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100daa:	0f b6 17             	movzbl (%edi),%edx
f0100dad:	0f b6 c2             	movzbl %dl,%eax
f0100db0:	83 ea 23             	sub    $0x23,%edx
f0100db3:	80 fa 55             	cmp    $0x55,%dl
f0100db6:	0f 87 bf 03 00 00    	ja     f010117b <vprintfmt+0x447>
f0100dbc:	0f b6 d2             	movzbl %dl,%edx
f0100dbf:	ff 24 95 c0 1e 10 f0 	jmp    *-0xfefe140(,%edx,4)
f0100dc6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dc9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100dd1:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100dd4:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100dd8:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100ddb:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100dde:	83 f9 09             	cmp    $0x9,%ecx
f0100de1:	77 3c                	ja     f0100e1f <vprintfmt+0xeb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100de3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100de6:	eb e9                	jmp    f0100dd1 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100de8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100deb:	8b 00                	mov    (%eax),%eax
f0100ded:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100df0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100df3:	8d 40 04             	lea    0x4(%eax),%eax
f0100df6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100dfc:	eb 27                	jmp    f0100e25 <vprintfmt+0xf1>
f0100dfe:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e01:	85 d2                	test   %edx,%edx
f0100e03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e08:	0f 49 c2             	cmovns %edx,%eax
f0100e0b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e11:	eb 91                	jmp    f0100da4 <vprintfmt+0x70>
f0100e13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e16:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e1d:	eb 85                	jmp    f0100da4 <vprintfmt+0x70>
f0100e1f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e22:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e25:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e29:	0f 89 75 ff ff ff    	jns    f0100da4 <vprintfmt+0x70>
f0100e2f:	e9 63 ff ff ff       	jmp    f0100d97 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e34:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e3a:	e9 65 ff ff ff       	jmp    f0100da4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3f:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e42:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e46:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e4a:	8b 00                	mov    (%eax),%eax
f0100e4c:	89 04 24             	mov    %eax,(%esp)
f0100e4f:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e54:	e9 00 ff ff ff       	jmp    f0100d59 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e59:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e5c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e60:	8b 00                	mov    (%eax),%eax
f0100e62:	99                   	cltd   
f0100e63:	31 d0                	xor    %edx,%eax
f0100e65:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e67:	83 f8 07             	cmp    $0x7,%eax
f0100e6a:	7f 0b                	jg     f0100e77 <vprintfmt+0x143>
f0100e6c:	8b 14 85 20 20 10 f0 	mov    -0xfefdfe0(,%eax,4),%edx
f0100e73:	85 d2                	test   %edx,%edx
f0100e75:	75 20                	jne    f0100e97 <vprintfmt+0x163>
				printfmt(putch, putdat, "error %d", err);
f0100e77:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e7b:	c7 44 24 08 39 1e 10 	movl   $0xf0101e39,0x8(%esp)
f0100e82:	f0 
f0100e83:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e87:	89 34 24             	mov    %esi,(%esp)
f0100e8a:	e8 7d fe ff ff       	call   f0100d0c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e92:	e9 c2 fe ff ff       	jmp    f0100d59 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100e97:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e9b:	c7 44 24 08 42 1e 10 	movl   $0xf0101e42,0x8(%esp)
f0100ea2:	f0 
f0100ea3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ea7:	89 34 24             	mov    %esi,(%esp)
f0100eaa:	e8 5d fe ff ff       	call   f0100d0c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eaf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eb2:	e9 a2 fe ff ff       	jmp    f0100d59 <vprintfmt+0x25>
f0100eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eba:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100ebd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ec0:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ec3:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ec7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ec9:	85 ff                	test   %edi,%edi
f0100ecb:	b8 32 1e 10 f0       	mov    $0xf0101e32,%eax
f0100ed0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ed3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100ed7:	0f 84 92 00 00 00    	je     f0100f6f <vprintfmt+0x23b>
f0100edd:	85 c9                	test   %ecx,%ecx
f0100edf:	0f 8e 98 00 00 00    	jle    f0100f7d <vprintfmt+0x249>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ee5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ee9:	89 3c 24             	mov    %edi,(%esp)
f0100eec:	e8 17 04 00 00       	call   f0101308 <strnlen>
f0100ef1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100ef4:	29 c1                	sub    %eax,%ecx
f0100ef6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0100ef9:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100efd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f00:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f03:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f05:	eb 0f                	jmp    f0100f16 <vprintfmt+0x1e2>
					putch(padc, putdat);
f0100f07:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f0e:	89 04 24             	mov    %eax,(%esp)
f0100f11:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f13:	83 ef 01             	sub    $0x1,%edi
f0100f16:	85 ff                	test   %edi,%edi
f0100f18:	7f ed                	jg     f0100f07 <vprintfmt+0x1d3>
f0100f1a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f1d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f20:	85 c9                	test   %ecx,%ecx
f0100f22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f27:	0f 49 c1             	cmovns %ecx,%eax
f0100f2a:	29 c1                	sub    %eax,%ecx
f0100f2c:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f2f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f32:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f35:	89 cb                	mov    %ecx,%ebx
f0100f37:	eb 50                	jmp    f0100f89 <vprintfmt+0x255>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f39:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f3d:	74 1e                	je     f0100f5d <vprintfmt+0x229>
f0100f3f:	0f be d2             	movsbl %dl,%edx
f0100f42:	83 ea 20             	sub    $0x20,%edx
f0100f45:	83 fa 5e             	cmp    $0x5e,%edx
f0100f48:	76 13                	jbe    f0100f5d <vprintfmt+0x229>
					putch('?', putdat);
f0100f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f51:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100f58:	ff 55 08             	call   *0x8(%ebp)
f0100f5b:	eb 0d                	jmp    f0100f6a <vprintfmt+0x236>
				else
					putch(ch, putdat);
f0100f5d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100f60:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f64:	89 04 24             	mov    %eax,(%esp)
f0100f67:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f6a:	83 eb 01             	sub    $0x1,%ebx
f0100f6d:	eb 1a                	jmp    f0100f89 <vprintfmt+0x255>
f0100f6f:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f72:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f75:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f78:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f7b:	eb 0c                	jmp    f0100f89 <vprintfmt+0x255>
f0100f7d:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f80:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f83:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f86:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f89:	83 c7 01             	add    $0x1,%edi
f0100f8c:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0100f90:	0f be c2             	movsbl %dl,%eax
f0100f93:	85 c0                	test   %eax,%eax
f0100f95:	74 25                	je     f0100fbc <vprintfmt+0x288>
f0100f97:	85 f6                	test   %esi,%esi
f0100f99:	78 9e                	js     f0100f39 <vprintfmt+0x205>
f0100f9b:	83 ee 01             	sub    $0x1,%esi
f0100f9e:	79 99                	jns    f0100f39 <vprintfmt+0x205>
f0100fa0:	89 df                	mov    %ebx,%edi
f0100fa2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fa5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa8:	eb 1a                	jmp    f0100fc4 <vprintfmt+0x290>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100faa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fae:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100fb5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fb7:	83 ef 01             	sub    $0x1,%edi
f0100fba:	eb 08                	jmp    f0100fc4 <vprintfmt+0x290>
f0100fbc:	89 df                	mov    %ebx,%edi
f0100fbe:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fc1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fc4:	85 ff                	test   %edi,%edi
f0100fc6:	7f e2                	jg     f0100faa <vprintfmt+0x276>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fcb:	e9 89 fd ff ff       	jmp    f0100d59 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fd0:	83 f9 01             	cmp    $0x1,%ecx
f0100fd3:	7e 19                	jle    f0100fee <vprintfmt+0x2ba>
		return va_arg(*ap, long long);
f0100fd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd8:	8b 50 04             	mov    0x4(%eax),%edx
f0100fdb:	8b 00                	mov    (%eax),%eax
f0100fdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fe0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fe3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe6:	8d 40 08             	lea    0x8(%eax),%eax
f0100fe9:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fec:	eb 38                	jmp    f0101026 <vprintfmt+0x2f2>
	else if (lflag)
f0100fee:	85 c9                	test   %ecx,%ecx
f0100ff0:	74 1b                	je     f010100d <vprintfmt+0x2d9>
		return va_arg(*ap, long);
f0100ff2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff5:	8b 00                	mov    (%eax),%eax
f0100ff7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ffa:	89 c1                	mov    %eax,%ecx
f0100ffc:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fff:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101002:	8b 45 14             	mov    0x14(%ebp),%eax
f0101005:	8d 40 04             	lea    0x4(%eax),%eax
f0101008:	89 45 14             	mov    %eax,0x14(%ebp)
f010100b:	eb 19                	jmp    f0101026 <vprintfmt+0x2f2>
	else
		return va_arg(*ap, int);
f010100d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101010:	8b 00                	mov    (%eax),%eax
f0101012:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101015:	89 c1                	mov    %eax,%ecx
f0101017:	c1 f9 1f             	sar    $0x1f,%ecx
f010101a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010101d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101020:	8d 40 04             	lea    0x4(%eax),%eax
f0101023:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101026:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101029:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010102c:	bf 0a 00 00 00       	mov    $0xa,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101031:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101035:	0f 89 04 01 00 00    	jns    f010113f <vprintfmt+0x40b>
				putch('-', putdat);
f010103b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010103f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101046:	ff d6                	call   *%esi
				num = -(long long) num;
f0101048:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010104b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010104e:	f7 da                	neg    %edx
f0101050:	83 d1 00             	adc    $0x0,%ecx
f0101053:	f7 d9                	neg    %ecx
f0101055:	e9 e5 00 00 00       	jmp    f010113f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010105a:	83 f9 01             	cmp    $0x1,%ecx
f010105d:	7e 10                	jle    f010106f <vprintfmt+0x33b>
		return va_arg(*ap, unsigned long long);
f010105f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101062:	8b 10                	mov    (%eax),%edx
f0101064:	8b 48 04             	mov    0x4(%eax),%ecx
f0101067:	8d 40 08             	lea    0x8(%eax),%eax
f010106a:	89 45 14             	mov    %eax,0x14(%ebp)
f010106d:	eb 26                	jmp    f0101095 <vprintfmt+0x361>
	else if (lflag)
f010106f:	85 c9                	test   %ecx,%ecx
f0101071:	74 12                	je     f0101085 <vprintfmt+0x351>
		return va_arg(*ap, unsigned long);
f0101073:	8b 45 14             	mov    0x14(%ebp),%eax
f0101076:	8b 10                	mov    (%eax),%edx
f0101078:	b9 00 00 00 00       	mov    $0x0,%ecx
f010107d:	8d 40 04             	lea    0x4(%eax),%eax
f0101080:	89 45 14             	mov    %eax,0x14(%ebp)
f0101083:	eb 10                	jmp    f0101095 <vprintfmt+0x361>
	else
		return va_arg(*ap, unsigned int);
f0101085:	8b 45 14             	mov    0x14(%ebp),%eax
f0101088:	8b 10                	mov    (%eax),%edx
f010108a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010108f:	8d 40 04             	lea    0x4(%eax),%eax
f0101092:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101095:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f010109a:	e9 a0 00 00 00       	jmp    f010113f <vprintfmt+0x40b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010109f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a3:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010aa:	ff d6                	call   *%esi
			putch('X', putdat);
f01010ac:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b0:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010b7:	ff d6                	call   *%esi
			putch('X', putdat);
f01010b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010bd:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010c4:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010c9:	e9 8b fc ff ff       	jmp    f0100d59 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f01010ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010d9:	ff d6                	call   *%esi
			putch('x', putdat);
f01010db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010df:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010e6:	ff d6                	call   *%esi
			num = (unsigned long long)
f01010e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010eb:	8b 10                	mov    (%eax),%edx
f01010ed:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f01010f2:	8d 40 04             	lea    0x4(%eax),%eax
f01010f5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010f8:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f01010fd:	eb 40                	jmp    f010113f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010ff:	83 f9 01             	cmp    $0x1,%ecx
f0101102:	7e 10                	jle    f0101114 <vprintfmt+0x3e0>
		return va_arg(*ap, unsigned long long);
f0101104:	8b 45 14             	mov    0x14(%ebp),%eax
f0101107:	8b 10                	mov    (%eax),%edx
f0101109:	8b 48 04             	mov    0x4(%eax),%ecx
f010110c:	8d 40 08             	lea    0x8(%eax),%eax
f010110f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101112:	eb 26                	jmp    f010113a <vprintfmt+0x406>
	else if (lflag)
f0101114:	85 c9                	test   %ecx,%ecx
f0101116:	74 12                	je     f010112a <vprintfmt+0x3f6>
		return va_arg(*ap, unsigned long);
f0101118:	8b 45 14             	mov    0x14(%ebp),%eax
f010111b:	8b 10                	mov    (%eax),%edx
f010111d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101122:	8d 40 04             	lea    0x4(%eax),%eax
f0101125:	89 45 14             	mov    %eax,0x14(%ebp)
f0101128:	eb 10                	jmp    f010113a <vprintfmt+0x406>
	else
		return va_arg(*ap, unsigned int);
f010112a:	8b 45 14             	mov    0x14(%ebp),%eax
f010112d:	8b 10                	mov    (%eax),%edx
f010112f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101134:	8d 40 04             	lea    0x4(%eax),%eax
f0101137:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010113a:	bf 10 00 00 00       	mov    $0x10,%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
f010113f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101143:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101147:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010114a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010114e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101152:	89 14 24             	mov    %edx,(%esp)
f0101155:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101159:	89 da                	mov    %ebx,%edx
f010115b:	89 f0                	mov    %esi,%eax
f010115d:	e8 9e fa ff ff       	call   f0100c00 <printnum>
			break;
f0101162:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101165:	e9 ef fb ff ff       	jmp    f0100d59 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010116a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010116e:	89 04 24             	mov    %eax,(%esp)
f0101171:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101173:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101176:	e9 de fb ff ff       	jmp    f0100d59 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010117b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010117f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101186:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101188:	eb 03                	jmp    f010118d <vprintfmt+0x459>
f010118a:	83 ef 01             	sub    $0x1,%edi
f010118d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101191:	75 f7                	jne    f010118a <vprintfmt+0x456>
f0101193:	e9 c1 fb ff ff       	jmp    f0100d59 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101198:	83 c4 3c             	add    $0x3c,%esp
f010119b:	5b                   	pop    %ebx
f010119c:	5e                   	pop    %esi
f010119d:	5f                   	pop    %edi
f010119e:	5d                   	pop    %ebp
f010119f:	c3                   	ret    

f01011a0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011a0:	55                   	push   %ebp
f01011a1:	89 e5                	mov    %esp,%ebp
f01011a3:	83 ec 28             	sub    $0x28,%esp
f01011a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011af:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011b3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011b6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011bd:	85 c0                	test   %eax,%eax
f01011bf:	74 30                	je     f01011f1 <vsnprintf+0x51>
f01011c1:	85 d2                	test   %edx,%edx
f01011c3:	7e 2c                	jle    f01011f1 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011cc:	8b 45 10             	mov    0x10(%ebp),%eax
f01011cf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011d3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011da:	c7 04 24 ef 0c 10 f0 	movl   $0xf0100cef,(%esp)
f01011e1:	e8 4e fb ff ff       	call   f0100d34 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ef:	eb 05                	jmp    f01011f6 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011f1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011f6:	c9                   	leave  
f01011f7:	c3                   	ret    

f01011f8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011f8:	55                   	push   %ebp
f01011f9:	89 e5                	mov    %esp,%ebp
f01011fb:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011fe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101201:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101205:	8b 45 10             	mov    0x10(%ebp),%eax
f0101208:	89 44 24 08          	mov    %eax,0x8(%esp)
f010120c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010120f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101213:	8b 45 08             	mov    0x8(%ebp),%eax
f0101216:	89 04 24             	mov    %eax,(%esp)
f0101219:	e8 82 ff ff ff       	call   f01011a0 <vsnprintf>
	va_end(ap);

	return rc;
}
f010121e:	c9                   	leave  
f010121f:	c3                   	ret    

f0101220 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101220:	55                   	push   %ebp
f0101221:	89 e5                	mov    %esp,%ebp
f0101223:	57                   	push   %edi
f0101224:	56                   	push   %esi
f0101225:	53                   	push   %ebx
f0101226:	83 ec 1c             	sub    $0x1c,%esp
f0101229:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010122c:	85 c0                	test   %eax,%eax
f010122e:	74 10                	je     f0101240 <readline+0x20>
		cprintf("%s", prompt);
f0101230:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101234:	c7 04 24 42 1e 10 f0 	movl   $0xf0101e42,(%esp)
f010123b:	e8 e1 f6 ff ff       	call   f0100921 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101240:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101247:	e8 26 f4 ff ff       	call   f0100672 <iscons>
f010124c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010124e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101253:	e8 09 f4 ff ff       	call   f0100661 <getchar>
f0101258:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010125a:	85 c0                	test   %eax,%eax
f010125c:	79 17                	jns    f0101275 <readline+0x55>
			cprintf("read error: %e\n", c);
f010125e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101262:	c7 04 24 40 20 10 f0 	movl   $0xf0102040,(%esp)
f0101269:	e8 b3 f6 ff ff       	call   f0100921 <cprintf>
			return NULL;
f010126e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101273:	eb 6d                	jmp    f01012e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101275:	83 f8 7f             	cmp    $0x7f,%eax
f0101278:	74 05                	je     f010127f <readline+0x5f>
f010127a:	83 f8 08             	cmp    $0x8,%eax
f010127d:	75 19                	jne    f0101298 <readline+0x78>
f010127f:	85 f6                	test   %esi,%esi
f0101281:	7e 15                	jle    f0101298 <readline+0x78>
			if (echoing)
f0101283:	85 ff                	test   %edi,%edi
f0101285:	74 0c                	je     f0101293 <readline+0x73>
				cputchar('\b');
f0101287:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010128e:	e8 be f3 ff ff       	call   f0100651 <cputchar>
			i--;
f0101293:	83 ee 01             	sub    $0x1,%esi
f0101296:	eb bb                	jmp    f0101253 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101298:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010129e:	7f 1c                	jg     f01012bc <readline+0x9c>
f01012a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012a3:	7e 17                	jle    f01012bc <readline+0x9c>
			if (echoing)
f01012a5:	85 ff                	test   %edi,%edi
f01012a7:	74 08                	je     f01012b1 <readline+0x91>
				cputchar(c);
f01012a9:	89 1c 24             	mov    %ebx,(%esp)
f01012ac:	e8 a0 f3 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f01012b1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012b7:	8d 76 01             	lea    0x1(%esi),%esi
f01012ba:	eb 97                	jmp    f0101253 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012bc:	83 fb 0d             	cmp    $0xd,%ebx
f01012bf:	74 05                	je     f01012c6 <readline+0xa6>
f01012c1:	83 fb 0a             	cmp    $0xa,%ebx
f01012c4:	75 8d                	jne    f0101253 <readline+0x33>
			if (echoing)
f01012c6:	85 ff                	test   %edi,%edi
f01012c8:	74 0c                	je     f01012d6 <readline+0xb6>
				cputchar('\n');
f01012ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012d1:	e8 7b f3 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f01012d6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012dd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012e2:	83 c4 1c             	add    $0x1c,%esp
f01012e5:	5b                   	pop    %ebx
f01012e6:	5e                   	pop    %esi
f01012e7:	5f                   	pop    %edi
f01012e8:	5d                   	pop    %ebp
f01012e9:	c3                   	ret    
f01012ea:	66 90                	xchg   %ax,%ax
f01012ec:	66 90                	xchg   %ax,%ax
f01012ee:	66 90                	xchg   %ax,%ax

f01012f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012fb:	eb 03                	jmp    f0101300 <strlen+0x10>
		n++;
f01012fd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101300:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101304:	75 f7                	jne    f01012fd <strlen+0xd>
		n++;
	return n;
}
f0101306:	5d                   	pop    %ebp
f0101307:	c3                   	ret    

f0101308 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101308:	55                   	push   %ebp
f0101309:	89 e5                	mov    %esp,%ebp
f010130b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010130e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101311:	b8 00 00 00 00       	mov    $0x0,%eax
f0101316:	eb 03                	jmp    f010131b <strnlen+0x13>
		n++;
f0101318:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010131b:	39 d0                	cmp    %edx,%eax
f010131d:	74 06                	je     f0101325 <strnlen+0x1d>
f010131f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101323:	75 f3                	jne    f0101318 <strnlen+0x10>
		n++;
	return n;
}
f0101325:	5d                   	pop    %ebp
f0101326:	c3                   	ret    

f0101327 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101327:	55                   	push   %ebp
f0101328:	89 e5                	mov    %esp,%ebp
f010132a:	53                   	push   %ebx
f010132b:	8b 45 08             	mov    0x8(%ebp),%eax
f010132e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101331:	89 c2                	mov    %eax,%edx
f0101333:	83 c2 01             	add    $0x1,%edx
f0101336:	83 c1 01             	add    $0x1,%ecx
f0101339:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010133d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101340:	84 db                	test   %bl,%bl
f0101342:	75 ef                	jne    f0101333 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101344:	5b                   	pop    %ebx
f0101345:	5d                   	pop    %ebp
f0101346:	c3                   	ret    

f0101347 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	53                   	push   %ebx
f010134b:	83 ec 08             	sub    $0x8,%esp
f010134e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101351:	89 1c 24             	mov    %ebx,(%esp)
f0101354:	e8 97 ff ff ff       	call   f01012f0 <strlen>
	strcpy(dst + len, src);
f0101359:	8b 55 0c             	mov    0xc(%ebp),%edx
f010135c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101360:	01 d8                	add    %ebx,%eax
f0101362:	89 04 24             	mov    %eax,(%esp)
f0101365:	e8 bd ff ff ff       	call   f0101327 <strcpy>
	return dst;
}
f010136a:	89 d8                	mov    %ebx,%eax
f010136c:	83 c4 08             	add    $0x8,%esp
f010136f:	5b                   	pop    %ebx
f0101370:	5d                   	pop    %ebp
f0101371:	c3                   	ret    

f0101372 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101372:	55                   	push   %ebp
f0101373:	89 e5                	mov    %esp,%ebp
f0101375:	56                   	push   %esi
f0101376:	53                   	push   %ebx
f0101377:	8b 75 08             	mov    0x8(%ebp),%esi
f010137a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010137d:	89 f3                	mov    %esi,%ebx
f010137f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101382:	89 f2                	mov    %esi,%edx
f0101384:	eb 0f                	jmp    f0101395 <strncpy+0x23>
		*dst++ = *src;
f0101386:	83 c2 01             	add    $0x1,%edx
f0101389:	0f b6 01             	movzbl (%ecx),%eax
f010138c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010138f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101392:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101395:	39 da                	cmp    %ebx,%edx
f0101397:	75 ed                	jne    f0101386 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101399:	89 f0                	mov    %esi,%eax
f010139b:	5b                   	pop    %ebx
f010139c:	5e                   	pop    %esi
f010139d:	5d                   	pop    %ebp
f010139e:	c3                   	ret    

f010139f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010139f:	55                   	push   %ebp
f01013a0:	89 e5                	mov    %esp,%ebp
f01013a2:	56                   	push   %esi
f01013a3:	53                   	push   %ebx
f01013a4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01013ad:	89 f0                	mov    %esi,%eax
f01013af:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013b3:	85 c9                	test   %ecx,%ecx
f01013b5:	75 0b                	jne    f01013c2 <strlcpy+0x23>
f01013b7:	eb 1d                	jmp    f01013d6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013b9:	83 c0 01             	add    $0x1,%eax
f01013bc:	83 c2 01             	add    $0x1,%edx
f01013bf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013c2:	39 d8                	cmp    %ebx,%eax
f01013c4:	74 0b                	je     f01013d1 <strlcpy+0x32>
f01013c6:	0f b6 0a             	movzbl (%edx),%ecx
f01013c9:	84 c9                	test   %cl,%cl
f01013cb:	75 ec                	jne    f01013b9 <strlcpy+0x1a>
f01013cd:	89 c2                	mov    %eax,%edx
f01013cf:	eb 02                	jmp    f01013d3 <strlcpy+0x34>
f01013d1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013d3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013d6:	29 f0                	sub    %esi,%eax
}
f01013d8:	5b                   	pop    %ebx
f01013d9:	5e                   	pop    %esi
f01013da:	5d                   	pop    %ebp
f01013db:	c3                   	ret    

f01013dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013dc:	55                   	push   %ebp
f01013dd:	89 e5                	mov    %esp,%ebp
f01013df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013e5:	eb 06                	jmp    f01013ed <strcmp+0x11>
		p++, q++;
f01013e7:	83 c1 01             	add    $0x1,%ecx
f01013ea:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013ed:	0f b6 01             	movzbl (%ecx),%eax
f01013f0:	84 c0                	test   %al,%al
f01013f2:	74 04                	je     f01013f8 <strcmp+0x1c>
f01013f4:	3a 02                	cmp    (%edx),%al
f01013f6:	74 ef                	je     f01013e7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013f8:	0f b6 c0             	movzbl %al,%eax
f01013fb:	0f b6 12             	movzbl (%edx),%edx
f01013fe:	29 d0                	sub    %edx,%eax
}
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	53                   	push   %ebx
f0101406:	8b 45 08             	mov    0x8(%ebp),%eax
f0101409:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140c:	89 c3                	mov    %eax,%ebx
f010140e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101411:	eb 06                	jmp    f0101419 <strncmp+0x17>
		n--, p++, q++;
f0101413:	83 c0 01             	add    $0x1,%eax
f0101416:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101419:	39 d8                	cmp    %ebx,%eax
f010141b:	74 15                	je     f0101432 <strncmp+0x30>
f010141d:	0f b6 08             	movzbl (%eax),%ecx
f0101420:	84 c9                	test   %cl,%cl
f0101422:	74 04                	je     f0101428 <strncmp+0x26>
f0101424:	3a 0a                	cmp    (%edx),%cl
f0101426:	74 eb                	je     f0101413 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101428:	0f b6 00             	movzbl (%eax),%eax
f010142b:	0f b6 12             	movzbl (%edx),%edx
f010142e:	29 d0                	sub    %edx,%eax
f0101430:	eb 05                	jmp    f0101437 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101432:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101437:	5b                   	pop    %ebx
f0101438:	5d                   	pop    %ebp
f0101439:	c3                   	ret    

f010143a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010143a:	55                   	push   %ebp
f010143b:	89 e5                	mov    %esp,%ebp
f010143d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101440:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101444:	eb 07                	jmp    f010144d <strchr+0x13>
		if (*s == c)
f0101446:	38 ca                	cmp    %cl,%dl
f0101448:	74 0f                	je     f0101459 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010144a:	83 c0 01             	add    $0x1,%eax
f010144d:	0f b6 10             	movzbl (%eax),%edx
f0101450:	84 d2                	test   %dl,%dl
f0101452:	75 f2                	jne    f0101446 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101454:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101459:	5d                   	pop    %ebp
f010145a:	c3                   	ret    

f010145b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101461:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101465:	eb 07                	jmp    f010146e <strfind+0x13>
		if (*s == c)
f0101467:	38 ca                	cmp    %cl,%dl
f0101469:	74 0a                	je     f0101475 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010146b:	83 c0 01             	add    $0x1,%eax
f010146e:	0f b6 10             	movzbl (%eax),%edx
f0101471:	84 d2                	test   %dl,%dl
f0101473:	75 f2                	jne    f0101467 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101475:	5d                   	pop    %ebp
f0101476:	c3                   	ret    

f0101477 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101477:	55                   	push   %ebp
f0101478:	89 e5                	mov    %esp,%ebp
f010147a:	57                   	push   %edi
f010147b:	56                   	push   %esi
f010147c:	53                   	push   %ebx
f010147d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101480:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101483:	85 c9                	test   %ecx,%ecx
f0101485:	74 36                	je     f01014bd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101487:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010148d:	75 28                	jne    f01014b7 <memset+0x40>
f010148f:	f6 c1 03             	test   $0x3,%cl
f0101492:	75 23                	jne    f01014b7 <memset+0x40>
		c &= 0xFF;
f0101494:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101498:	89 d3                	mov    %edx,%ebx
f010149a:	c1 e3 08             	shl    $0x8,%ebx
f010149d:	89 d6                	mov    %edx,%esi
f010149f:	c1 e6 18             	shl    $0x18,%esi
f01014a2:	89 d0                	mov    %edx,%eax
f01014a4:	c1 e0 10             	shl    $0x10,%eax
f01014a7:	09 f0                	or     %esi,%eax
f01014a9:	09 c2                	or     %eax,%edx
f01014ab:	89 d0                	mov    %edx,%eax
f01014ad:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014af:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014b2:	fc                   	cld    
f01014b3:	f3 ab                	rep stos %eax,%es:(%edi)
f01014b5:	eb 06                	jmp    f01014bd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ba:	fc                   	cld    
f01014bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014bd:	89 f8                	mov    %edi,%eax
f01014bf:	5b                   	pop    %ebx
f01014c0:	5e                   	pop    %esi
f01014c1:	5f                   	pop    %edi
f01014c2:	5d                   	pop    %ebp
f01014c3:	c3                   	ret    

f01014c4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014c4:	55                   	push   %ebp
f01014c5:	89 e5                	mov    %esp,%ebp
f01014c7:	57                   	push   %edi
f01014c8:	56                   	push   %esi
f01014c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014d2:	39 c6                	cmp    %eax,%esi
f01014d4:	73 35                	jae    f010150b <memmove+0x47>
f01014d6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014d9:	39 d0                	cmp    %edx,%eax
f01014db:	73 2e                	jae    f010150b <memmove+0x47>
		s += n;
		d += n;
f01014dd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01014e0:	89 d6                	mov    %edx,%esi
f01014e2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014e4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014ea:	75 13                	jne    f01014ff <memmove+0x3b>
f01014ec:	f6 c1 03             	test   $0x3,%cl
f01014ef:	75 0e                	jne    f01014ff <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014f1:	83 ef 04             	sub    $0x4,%edi
f01014f4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014f7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01014fa:	fd                   	std    
f01014fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014fd:	eb 09                	jmp    f0101508 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01014ff:	83 ef 01             	sub    $0x1,%edi
f0101502:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101505:	fd                   	std    
f0101506:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101508:	fc                   	cld    
f0101509:	eb 1d                	jmp    f0101528 <memmove+0x64>
f010150b:	89 f2                	mov    %esi,%edx
f010150d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010150f:	f6 c2 03             	test   $0x3,%dl
f0101512:	75 0f                	jne    f0101523 <memmove+0x5f>
f0101514:	f6 c1 03             	test   $0x3,%cl
f0101517:	75 0a                	jne    f0101523 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101519:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010151c:	89 c7                	mov    %eax,%edi
f010151e:	fc                   	cld    
f010151f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101521:	eb 05                	jmp    f0101528 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101523:	89 c7                	mov    %eax,%edi
f0101525:	fc                   	cld    
f0101526:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101528:	5e                   	pop    %esi
f0101529:	5f                   	pop    %edi
f010152a:	5d                   	pop    %ebp
f010152b:	c3                   	ret    

f010152c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010152c:	55                   	push   %ebp
f010152d:	89 e5                	mov    %esp,%ebp
f010152f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101532:	8b 45 10             	mov    0x10(%ebp),%eax
f0101535:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101539:	8b 45 0c             	mov    0xc(%ebp),%eax
f010153c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101540:	8b 45 08             	mov    0x8(%ebp),%eax
f0101543:	89 04 24             	mov    %eax,(%esp)
f0101546:	e8 79 ff ff ff       	call   f01014c4 <memmove>
}
f010154b:	c9                   	leave  
f010154c:	c3                   	ret    

f010154d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010154d:	55                   	push   %ebp
f010154e:	89 e5                	mov    %esp,%ebp
f0101550:	56                   	push   %esi
f0101551:	53                   	push   %ebx
f0101552:	8b 55 08             	mov    0x8(%ebp),%edx
f0101555:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101558:	89 d6                	mov    %edx,%esi
f010155a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010155d:	eb 1a                	jmp    f0101579 <memcmp+0x2c>
		if (*s1 != *s2)
f010155f:	0f b6 02             	movzbl (%edx),%eax
f0101562:	0f b6 19             	movzbl (%ecx),%ebx
f0101565:	38 d8                	cmp    %bl,%al
f0101567:	74 0a                	je     f0101573 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101569:	0f b6 c0             	movzbl %al,%eax
f010156c:	0f b6 db             	movzbl %bl,%ebx
f010156f:	29 d8                	sub    %ebx,%eax
f0101571:	eb 0f                	jmp    f0101582 <memcmp+0x35>
		s1++, s2++;
f0101573:	83 c2 01             	add    $0x1,%edx
f0101576:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101579:	39 f2                	cmp    %esi,%edx
f010157b:	75 e2                	jne    f010155f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010157d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101582:	5b                   	pop    %ebx
f0101583:	5e                   	pop    %esi
f0101584:	5d                   	pop    %ebp
f0101585:	c3                   	ret    

f0101586 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101586:	55                   	push   %ebp
f0101587:	89 e5                	mov    %esp,%ebp
f0101589:	8b 45 08             	mov    0x8(%ebp),%eax
f010158c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010158f:	89 c2                	mov    %eax,%edx
f0101591:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101594:	eb 07                	jmp    f010159d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101596:	38 08                	cmp    %cl,(%eax)
f0101598:	74 07                	je     f01015a1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010159a:	83 c0 01             	add    $0x1,%eax
f010159d:	39 d0                	cmp    %edx,%eax
f010159f:	72 f5                	jb     f0101596 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015a1:	5d                   	pop    %ebp
f01015a2:	c3                   	ret    

f01015a3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015a3:	55                   	push   %ebp
f01015a4:	89 e5                	mov    %esp,%ebp
f01015a6:	57                   	push   %edi
f01015a7:	56                   	push   %esi
f01015a8:	53                   	push   %ebx
f01015a9:	8b 55 08             	mov    0x8(%ebp),%edx
f01015ac:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015af:	eb 03                	jmp    f01015b4 <strtol+0x11>
		s++;
f01015b1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015b4:	0f b6 0a             	movzbl (%edx),%ecx
f01015b7:	80 f9 09             	cmp    $0x9,%cl
f01015ba:	74 f5                	je     f01015b1 <strtol+0xe>
f01015bc:	80 f9 20             	cmp    $0x20,%cl
f01015bf:	74 f0                	je     f01015b1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015c1:	80 f9 2b             	cmp    $0x2b,%cl
f01015c4:	75 0a                	jne    f01015d0 <strtol+0x2d>
		s++;
f01015c6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015c9:	bf 00 00 00 00       	mov    $0x0,%edi
f01015ce:	eb 11                	jmp    f01015e1 <strtol+0x3e>
f01015d0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015d5:	80 f9 2d             	cmp    $0x2d,%cl
f01015d8:	75 07                	jne    f01015e1 <strtol+0x3e>
		s++, neg = 1;
f01015da:	8d 52 01             	lea    0x1(%edx),%edx
f01015dd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015e1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01015e6:	75 15                	jne    f01015fd <strtol+0x5a>
f01015e8:	80 3a 30             	cmpb   $0x30,(%edx)
f01015eb:	75 10                	jne    f01015fd <strtol+0x5a>
f01015ed:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01015f1:	75 0a                	jne    f01015fd <strtol+0x5a>
		s += 2, base = 16;
f01015f3:	83 c2 02             	add    $0x2,%edx
f01015f6:	b8 10 00 00 00       	mov    $0x10,%eax
f01015fb:	eb 10                	jmp    f010160d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01015fd:	85 c0                	test   %eax,%eax
f01015ff:	75 0c                	jne    f010160d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101601:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101603:	80 3a 30             	cmpb   $0x30,(%edx)
f0101606:	75 05                	jne    f010160d <strtol+0x6a>
		s++, base = 8;
f0101608:	83 c2 01             	add    $0x1,%edx
f010160b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010160d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101612:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101615:	0f b6 0a             	movzbl (%edx),%ecx
f0101618:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010161b:	89 f0                	mov    %esi,%eax
f010161d:	3c 09                	cmp    $0x9,%al
f010161f:	77 08                	ja     f0101629 <strtol+0x86>
			dig = *s - '0';
f0101621:	0f be c9             	movsbl %cl,%ecx
f0101624:	83 e9 30             	sub    $0x30,%ecx
f0101627:	eb 20                	jmp    f0101649 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101629:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010162c:	89 f0                	mov    %esi,%eax
f010162e:	3c 19                	cmp    $0x19,%al
f0101630:	77 08                	ja     f010163a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101632:	0f be c9             	movsbl %cl,%ecx
f0101635:	83 e9 57             	sub    $0x57,%ecx
f0101638:	eb 0f                	jmp    f0101649 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010163a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010163d:	89 f0                	mov    %esi,%eax
f010163f:	3c 19                	cmp    $0x19,%al
f0101641:	77 16                	ja     f0101659 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101643:	0f be c9             	movsbl %cl,%ecx
f0101646:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101649:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010164c:	7d 0f                	jge    f010165d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010164e:	83 c2 01             	add    $0x1,%edx
f0101651:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101655:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101657:	eb bc                	jmp    f0101615 <strtol+0x72>
f0101659:	89 d8                	mov    %ebx,%eax
f010165b:	eb 02                	jmp    f010165f <strtol+0xbc>
f010165d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010165f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101663:	74 05                	je     f010166a <strtol+0xc7>
		*endptr = (char *) s;
f0101665:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101668:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010166a:	f7 d8                	neg    %eax
f010166c:	85 ff                	test   %edi,%edi
f010166e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101671:	5b                   	pop    %ebx
f0101672:	5e                   	pop    %esi
f0101673:	5f                   	pop    %edi
f0101674:	5d                   	pop    %ebp
f0101675:	c3                   	ret    
f0101676:	66 90                	xchg   %ax,%ax
f0101678:	66 90                	xchg   %ax,%ax
f010167a:	66 90                	xchg   %ax,%ax
f010167c:	66 90                	xchg   %ax,%ax
f010167e:	66 90                	xchg   %ax,%ax

f0101680 <__udivdi3>:
f0101680:	55                   	push   %ebp
f0101681:	57                   	push   %edi
f0101682:	56                   	push   %esi
f0101683:	83 ec 0c             	sub    $0xc,%esp
f0101686:	8b 44 24 28          	mov    0x28(%esp),%eax
f010168a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010168e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101692:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101696:	85 c0                	test   %eax,%eax
f0101698:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010169c:	89 ea                	mov    %ebp,%edx
f010169e:	89 0c 24             	mov    %ecx,(%esp)
f01016a1:	75 2d                	jne    f01016d0 <__udivdi3+0x50>
f01016a3:	39 e9                	cmp    %ebp,%ecx
f01016a5:	77 61                	ja     f0101708 <__udivdi3+0x88>
f01016a7:	85 c9                	test   %ecx,%ecx
f01016a9:	89 ce                	mov    %ecx,%esi
f01016ab:	75 0b                	jne    f01016b8 <__udivdi3+0x38>
f01016ad:	b8 01 00 00 00       	mov    $0x1,%eax
f01016b2:	31 d2                	xor    %edx,%edx
f01016b4:	f7 f1                	div    %ecx
f01016b6:	89 c6                	mov    %eax,%esi
f01016b8:	31 d2                	xor    %edx,%edx
f01016ba:	89 e8                	mov    %ebp,%eax
f01016bc:	f7 f6                	div    %esi
f01016be:	89 c5                	mov    %eax,%ebp
f01016c0:	89 f8                	mov    %edi,%eax
f01016c2:	f7 f6                	div    %esi
f01016c4:	89 ea                	mov    %ebp,%edx
f01016c6:	83 c4 0c             	add    $0xc,%esp
f01016c9:	5e                   	pop    %esi
f01016ca:	5f                   	pop    %edi
f01016cb:	5d                   	pop    %ebp
f01016cc:	c3                   	ret    
f01016cd:	8d 76 00             	lea    0x0(%esi),%esi
f01016d0:	39 e8                	cmp    %ebp,%eax
f01016d2:	77 24                	ja     f01016f8 <__udivdi3+0x78>
f01016d4:	0f bd e8             	bsr    %eax,%ebp
f01016d7:	83 f5 1f             	xor    $0x1f,%ebp
f01016da:	75 3c                	jne    f0101718 <__udivdi3+0x98>
f01016dc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01016e0:	39 34 24             	cmp    %esi,(%esp)
f01016e3:	0f 86 9f 00 00 00    	jbe    f0101788 <__udivdi3+0x108>
f01016e9:	39 d0                	cmp    %edx,%eax
f01016eb:	0f 82 97 00 00 00    	jb     f0101788 <__udivdi3+0x108>
f01016f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016f8:	31 d2                	xor    %edx,%edx
f01016fa:	31 c0                	xor    %eax,%eax
f01016fc:	83 c4 0c             	add    $0xc,%esp
f01016ff:	5e                   	pop    %esi
f0101700:	5f                   	pop    %edi
f0101701:	5d                   	pop    %ebp
f0101702:	c3                   	ret    
f0101703:	90                   	nop
f0101704:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101708:	89 f8                	mov    %edi,%eax
f010170a:	f7 f1                	div    %ecx
f010170c:	31 d2                	xor    %edx,%edx
f010170e:	83 c4 0c             	add    $0xc,%esp
f0101711:	5e                   	pop    %esi
f0101712:	5f                   	pop    %edi
f0101713:	5d                   	pop    %ebp
f0101714:	c3                   	ret    
f0101715:	8d 76 00             	lea    0x0(%esi),%esi
f0101718:	89 e9                	mov    %ebp,%ecx
f010171a:	8b 3c 24             	mov    (%esp),%edi
f010171d:	d3 e0                	shl    %cl,%eax
f010171f:	89 c6                	mov    %eax,%esi
f0101721:	b8 20 00 00 00       	mov    $0x20,%eax
f0101726:	29 e8                	sub    %ebp,%eax
f0101728:	89 c1                	mov    %eax,%ecx
f010172a:	d3 ef                	shr    %cl,%edi
f010172c:	89 e9                	mov    %ebp,%ecx
f010172e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101732:	8b 3c 24             	mov    (%esp),%edi
f0101735:	09 74 24 08          	or     %esi,0x8(%esp)
f0101739:	89 d6                	mov    %edx,%esi
f010173b:	d3 e7                	shl    %cl,%edi
f010173d:	89 c1                	mov    %eax,%ecx
f010173f:	89 3c 24             	mov    %edi,(%esp)
f0101742:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101746:	d3 ee                	shr    %cl,%esi
f0101748:	89 e9                	mov    %ebp,%ecx
f010174a:	d3 e2                	shl    %cl,%edx
f010174c:	89 c1                	mov    %eax,%ecx
f010174e:	d3 ef                	shr    %cl,%edi
f0101750:	09 d7                	or     %edx,%edi
f0101752:	89 f2                	mov    %esi,%edx
f0101754:	89 f8                	mov    %edi,%eax
f0101756:	f7 74 24 08          	divl   0x8(%esp)
f010175a:	89 d6                	mov    %edx,%esi
f010175c:	89 c7                	mov    %eax,%edi
f010175e:	f7 24 24             	mull   (%esp)
f0101761:	39 d6                	cmp    %edx,%esi
f0101763:	89 14 24             	mov    %edx,(%esp)
f0101766:	72 30                	jb     f0101798 <__udivdi3+0x118>
f0101768:	8b 54 24 04          	mov    0x4(%esp),%edx
f010176c:	89 e9                	mov    %ebp,%ecx
f010176e:	d3 e2                	shl    %cl,%edx
f0101770:	39 c2                	cmp    %eax,%edx
f0101772:	73 05                	jae    f0101779 <__udivdi3+0xf9>
f0101774:	3b 34 24             	cmp    (%esp),%esi
f0101777:	74 1f                	je     f0101798 <__udivdi3+0x118>
f0101779:	89 f8                	mov    %edi,%eax
f010177b:	31 d2                	xor    %edx,%edx
f010177d:	e9 7a ff ff ff       	jmp    f01016fc <__udivdi3+0x7c>
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	31 d2                	xor    %edx,%edx
f010178a:	b8 01 00 00 00       	mov    $0x1,%eax
f010178f:	e9 68 ff ff ff       	jmp    f01016fc <__udivdi3+0x7c>
f0101794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101798:	8d 47 ff             	lea    -0x1(%edi),%eax
f010179b:	31 d2                	xor    %edx,%edx
f010179d:	83 c4 0c             	add    $0xc,%esp
f01017a0:	5e                   	pop    %esi
f01017a1:	5f                   	pop    %edi
f01017a2:	5d                   	pop    %ebp
f01017a3:	c3                   	ret    
f01017a4:	66 90                	xchg   %ax,%ax
f01017a6:	66 90                	xchg   %ax,%ax
f01017a8:	66 90                	xchg   %ax,%ax
f01017aa:	66 90                	xchg   %ax,%ax
f01017ac:	66 90                	xchg   %ax,%ax
f01017ae:	66 90                	xchg   %ax,%ax

f01017b0 <__umoddi3>:
f01017b0:	55                   	push   %ebp
f01017b1:	57                   	push   %edi
f01017b2:	56                   	push   %esi
f01017b3:	83 ec 14             	sub    $0x14,%esp
f01017b6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ba:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017be:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01017c2:	89 c7                	mov    %eax,%edi
f01017c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017c8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01017cc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01017d0:	89 34 24             	mov    %esi,(%esp)
f01017d3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017d7:	85 c0                	test   %eax,%eax
f01017d9:	89 c2                	mov    %eax,%edx
f01017db:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017df:	75 17                	jne    f01017f8 <__umoddi3+0x48>
f01017e1:	39 fe                	cmp    %edi,%esi
f01017e3:	76 4b                	jbe    f0101830 <__umoddi3+0x80>
f01017e5:	89 c8                	mov    %ecx,%eax
f01017e7:	89 fa                	mov    %edi,%edx
f01017e9:	f7 f6                	div    %esi
f01017eb:	89 d0                	mov    %edx,%eax
f01017ed:	31 d2                	xor    %edx,%edx
f01017ef:	83 c4 14             	add    $0x14,%esp
f01017f2:	5e                   	pop    %esi
f01017f3:	5f                   	pop    %edi
f01017f4:	5d                   	pop    %ebp
f01017f5:	c3                   	ret    
f01017f6:	66 90                	xchg   %ax,%ax
f01017f8:	39 f8                	cmp    %edi,%eax
f01017fa:	77 54                	ja     f0101850 <__umoddi3+0xa0>
f01017fc:	0f bd e8             	bsr    %eax,%ebp
f01017ff:	83 f5 1f             	xor    $0x1f,%ebp
f0101802:	75 5c                	jne    f0101860 <__umoddi3+0xb0>
f0101804:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101808:	39 3c 24             	cmp    %edi,(%esp)
f010180b:	0f 87 e7 00 00 00    	ja     f01018f8 <__umoddi3+0x148>
f0101811:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101815:	29 f1                	sub    %esi,%ecx
f0101817:	19 c7                	sbb    %eax,%edi
f0101819:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010181d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101821:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101825:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101829:	83 c4 14             	add    $0x14,%esp
f010182c:	5e                   	pop    %esi
f010182d:	5f                   	pop    %edi
f010182e:	5d                   	pop    %ebp
f010182f:	c3                   	ret    
f0101830:	85 f6                	test   %esi,%esi
f0101832:	89 f5                	mov    %esi,%ebp
f0101834:	75 0b                	jne    f0101841 <__umoddi3+0x91>
f0101836:	b8 01 00 00 00       	mov    $0x1,%eax
f010183b:	31 d2                	xor    %edx,%edx
f010183d:	f7 f6                	div    %esi
f010183f:	89 c5                	mov    %eax,%ebp
f0101841:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101845:	31 d2                	xor    %edx,%edx
f0101847:	f7 f5                	div    %ebp
f0101849:	89 c8                	mov    %ecx,%eax
f010184b:	f7 f5                	div    %ebp
f010184d:	eb 9c                	jmp    f01017eb <__umoddi3+0x3b>
f010184f:	90                   	nop
f0101850:	89 c8                	mov    %ecx,%eax
f0101852:	89 fa                	mov    %edi,%edx
f0101854:	83 c4 14             	add    $0x14,%esp
f0101857:	5e                   	pop    %esi
f0101858:	5f                   	pop    %edi
f0101859:	5d                   	pop    %ebp
f010185a:	c3                   	ret    
f010185b:	90                   	nop
f010185c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101860:	8b 04 24             	mov    (%esp),%eax
f0101863:	be 20 00 00 00       	mov    $0x20,%esi
f0101868:	89 e9                	mov    %ebp,%ecx
f010186a:	29 ee                	sub    %ebp,%esi
f010186c:	d3 e2                	shl    %cl,%edx
f010186e:	89 f1                	mov    %esi,%ecx
f0101870:	d3 e8                	shr    %cl,%eax
f0101872:	89 e9                	mov    %ebp,%ecx
f0101874:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101878:	8b 04 24             	mov    (%esp),%eax
f010187b:	09 54 24 04          	or     %edx,0x4(%esp)
f010187f:	89 fa                	mov    %edi,%edx
f0101881:	d3 e0                	shl    %cl,%eax
f0101883:	89 f1                	mov    %esi,%ecx
f0101885:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101889:	8b 44 24 10          	mov    0x10(%esp),%eax
f010188d:	d3 ea                	shr    %cl,%edx
f010188f:	89 e9                	mov    %ebp,%ecx
f0101891:	d3 e7                	shl    %cl,%edi
f0101893:	89 f1                	mov    %esi,%ecx
f0101895:	d3 e8                	shr    %cl,%eax
f0101897:	89 e9                	mov    %ebp,%ecx
f0101899:	09 f8                	or     %edi,%eax
f010189b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010189f:	f7 74 24 04          	divl   0x4(%esp)
f01018a3:	d3 e7                	shl    %cl,%edi
f01018a5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018a9:	89 d7                	mov    %edx,%edi
f01018ab:	f7 64 24 08          	mull   0x8(%esp)
f01018af:	39 d7                	cmp    %edx,%edi
f01018b1:	89 c1                	mov    %eax,%ecx
f01018b3:	89 14 24             	mov    %edx,(%esp)
f01018b6:	72 2c                	jb     f01018e4 <__umoddi3+0x134>
f01018b8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01018bc:	72 22                	jb     f01018e0 <__umoddi3+0x130>
f01018be:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018c2:	29 c8                	sub    %ecx,%eax
f01018c4:	19 d7                	sbb    %edx,%edi
f01018c6:	89 e9                	mov    %ebp,%ecx
f01018c8:	89 fa                	mov    %edi,%edx
f01018ca:	d3 e8                	shr    %cl,%eax
f01018cc:	89 f1                	mov    %esi,%ecx
f01018ce:	d3 e2                	shl    %cl,%edx
f01018d0:	89 e9                	mov    %ebp,%ecx
f01018d2:	d3 ef                	shr    %cl,%edi
f01018d4:	09 d0                	or     %edx,%eax
f01018d6:	89 fa                	mov    %edi,%edx
f01018d8:	83 c4 14             	add    $0x14,%esp
f01018db:	5e                   	pop    %esi
f01018dc:	5f                   	pop    %edi
f01018dd:	5d                   	pop    %ebp
f01018de:	c3                   	ret    
f01018df:	90                   	nop
f01018e0:	39 d7                	cmp    %edx,%edi
f01018e2:	75 da                	jne    f01018be <__umoddi3+0x10e>
f01018e4:	8b 14 24             	mov    (%esp),%edx
f01018e7:	89 c1                	mov    %eax,%ecx
f01018e9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01018ed:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01018f1:	eb cb                	jmp    f01018be <__umoddi3+0x10e>
f01018f3:	90                   	nop
f01018f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01018fc:	0f 82 0f ff ff ff    	jb     f0101811 <__umoddi3+0x61>
f0101902:	e9 1a ff ff ff       	jmp    f0101821 <__umoddi3+0x71>
