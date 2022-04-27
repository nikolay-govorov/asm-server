	section .text
	global _start

_start: mov rax, 41	; create socket (SYS_SOCKET, opcode 41)
	mov rdi, 2	; family   = PF_INET
	mov rsi, 1	; type     = SOCK_STREAM
	mov rdx, 6	; protocol = IPPROTO_TCP
	syscall

	; bind
	push qword 0	; end struct on stack (arguments get pushed in reverse order)
	push word 0x6022 ; move port=htons(8800) on stack
	push word 2	; move family onto stack AF_INET=2
	mov rdi, rax	; save listen descriptor
	mov rsi, rsp	; save sokaddr ptr
	mov rdx, 0x10	; save addrlen
	mov rax, 49	; bind socket (SYS_BIND, opcode 49) 
	syscall

_listen:
	mov rsi, 64	; backlog=64
	mov rax, 50	; listen socket (SYS_LISTEN, opcode 50)
	syscall

	; accept
	mov rsi, 0
	mov rdx, 0
	mov rax, 43	; accept socket (SYS_ACCEPT, opcode 43)
	syscall

	; fork
	mov rsi, rax	; move return value of SYS_SOCKET into esi (file descriptor for accepted socket, or -1 on error)
	mov rax, 57	; create a new process by request (SYS_FORK, opcode 2)
	syscall

	test rax, rax	; if return value of SYS_FORK in eax is zero we are in the child process
	jnz _listen	; jmp on new listen iterration if it not child process

	; write
	mov rdi, rsi	; move accepted file descriptor
	mov rsi, msg	; move reponse address
	mov rdx, msg_l	; move response size 
	mov rax, 1	; write on socket (SYS_WRITE)
	syscall
	mov rax, 3	; close listen descriptor (SYS_CLOSE)
	mov rdi, rdi
	syscall
	mov rax, 3	; close accept descriptor (SYS_CLOSE)
	mov rdi, rsi
	syscall

_exit:	mov rax, 60	; invoke SYS_EXIT
	mov rbx, 0	; 0 errors
	syscall

	section .data

msg:	db "HTTP/1.1 200 OK",13,10,"content-length: 15",13,10,"content-type: text/html",13,10,10,"<h1>Hello!</h1>"
msg_l:	equ $-msg