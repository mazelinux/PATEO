19219 hemiao
1.介绍一下你做过的模块
    tp,lcd,camera
2.tp如何在系统睡眠的情况下唤醒系统(功能)
    1.
    首先要保证的是,tp驱动正常的suspend流程不睡眠;[硬件上要保证不断电]
    request_irq 的flag加irq_no_suspend;
    修改suspend流程,suspend流程里面加入flag全局变量为1;
    修改正常的irq下半部,if flag == 1此时触摸屏幕,则上报keyevent_Power事件;
    修改resume流程,resume流程里面把flag全局变量置0

    2. suspend :enable_irq_wakeup
       resuem  :disable_irq_wakeup

3.什么是原子操作;i++是不是原子操作
    linux原子操作问题来源于中断、进程的抢占以及多核smp系统中程序的并发执行。
    原子操作：不可被中断的一个或一系列的操作。

    一.整型原子操作
        定义于#include<asm/atomic.h>
        分为 定义，获取，加减，测试，返回。

        void atomic_set(atomic_t *v,int i);    //设置原子变量v的值为i
        atomic_t v = ATOMIC_INIT(0);     //定义原子变量v,并初始化为0;

        atomic_read(atomic_t* v);     //返回原子变量v的值;

        void atomic_add(int i, atomic_t* v);     //原子变量v增加i;
        void atomic_sub(int i, atomic_t* v);    

        void atomic_inc(atomic_t* v);     //原子变量增加1;
        void atomic_dec(atomic_t* v);     

        int atomic_inc_and_test(atomic_t* v);        //先自增1,然后测试其值是否为0,若为0,则返回true,否则返回false;
        int atomic_dec_and_test(atomic_t* v);        
        int atomic_sub_and_test(int i, atomic_t* v);     //先减i,然后测试其值是否为0,若为0,则返回true,否则返回false;
        注意：只有自加，没有加操作

        int atomic_add_return(int i, atomic_t* v);   //v的值加i后返回新的值;
        int atomic_sub_return(int i, atomic_t* v);  
        int atomic_inc_return(atomic_t* v);     //v的值自增1后返回新的值;
        int atomic_dec_return(atomic_t* v);    

    二.位原子操作
        定义于#include<asm/bitops.h>
        分为 设置，清除，改变，测试

        void set_bit(int nr, volatile void* addr);        //设置地址addr的第nr位,所谓设置位,就是把位写为1;
        void clear_bit(int nr, volatile void* addr);      //清除地址addr的第nr位,所谓清除位,就是把位写为0;

        void change_bit(int nr, volatile void* addr);     //把地址addr的第nr位反转;

        int test_bit(int nr, volatile void* addr);    //返回地址addr的第nr位;

        int test_and_set_bit(int nr, volatile void* addr);    //测试并设置位;若addr的第nr位非0,则返回true; 若addr的第nr位为0,则返回false;
        int test_and_clear_bit(int nr, volatile void* addr);    //测试并清除位;
        int test_and_change_bit(int nr, volatile void* addr);    //测试并反转位;
        上述操作等同于先执行test_bit(nr,voidaddr)然后在执行xxx_bit(nr,addr)


    i++分为三个阶段：       asm {
    内存到寄存器            mov eax,dword ptr[i]
    寄存器自增              inc eax
    写回内存                mov dword ptr[i], eax}
    这三个阶段中间都可以被中断分离开.
    这种情况下，必定不是原子操作，不加锁互斥是不行的。
    假设加了优化参数，那么是否一定会编译为“inc dword ptr[i]”呢？答案是否定的，这要看编译器心情，如果++i的结果还要被使用的话，那么一定不会被编译为“inc dword ptr[i]”的形式。
    那么假设如果编译成了“inc dword ptr[i]”，这是原子操作，是否就不需要加锁了呢？如果在单核机器上，不加锁不会有问题，但到了多核机器上，这个不加锁同样会带来严重后果，两个CPU可以同时执行inc指令，但是两个执行以后，却可能出现只自加了一次。
    真正可以确保不“额外”加锁的汇编指令是“lock inc dword ptr[i]”，lock前缀可以暂时锁住总线，这时候其他CPU是无法访问相应数据的。但是目前没有任何一个编译器会将++int编译为这种形式。

4.进程间通信
    每个进程各自有不同的用户地址空间,任何一个进程的全局变量在另一个进程中都看不到所以进程之间要交换数据必须通过内核,在内核中开辟一块缓冲区,进程1把数据从用户空间拷到内核缓冲区,进程2再从内核缓冲区把数据读走,内核提供的这种机制称为进程间通信 (IPC,InterProcess Com）
     1.管道（Pipe）及有名管道（named pipe）：管道可用于具有亲缘关系进程间的通信，有名管道克服了管道没有名字的限制，因此，除具有管道所具有的功能外，它还允许无亲缘关系进程间的通信；    
     2.信号（Signal）：信号是比较复杂的通信方式，用于通知接受进程有某种事件生，除了用于进程间通信外，进程还可以发送信号给进程本身；linux除了支持Unix早期信号语义函数sigal外，还支持语义符合Posix.1标准的信号函数sigaction（实际上，该函数是基于BSD的，BSD为了实现可靠信号机制，又能够统一对外接口，sigaction函数重新实现了signal函数） 
     3.报文（Message）队列（消息队列）：消息队列是消息的链接表，包括Posix消息队列,system V消息队列。有足够权限的进程可以向队列中添加消息，被赋予读权限的进程则可以读走队列中的消息。消息队列克服了信号承载信息量少，管道只能承载无格式字节流以及缓冲区大小受限等缺点。
     4.共享内存：使得多个进程可以访问同一块内存空间，是最快的可用IPC形式。是针其他通信机制运行效率较低设计的。往往与其它通信机制，如信号量结合使用，来达到进程间的同步及互斥。
     5.信号量（semaphore）：主要作为进程间以及同一进程不同线程之间的同步手段。经常配合共享内存一起使用
     6.套接字（Socket）：更为一般的进程间通信机制，可用于不同机器之间的进程间通信。起初是由Unix系统的BSD分支开发出来的，但现在一般可以移植到其它类Unix 系统上：Linux和System V的变种都支持套接字。

======================
    管道是进程间通信中最古老的方式，它包括无名管道和有名管道两种，前者用于父进程和子进程间,兄弟进程间的通信，后者用于运行于同一台机器上的任意两个进程间的通信。

    1.无名管道[pipe]
    　  下面的例子示范了如何在父进程和子进程间实现通信;file_descriptors[0为读句柄/1为写句柄]
    　  #include <unistd.h>
        #define INPUT 0
        #define OUTPUT 1

        void main() {
            int file_descriptors[2];
            pid_t pid;                              /*定义子进程号 */
            char buf[256];
            int returned_count;

            pipe(file_descriptors);                 /*创建无名管道*/
            if((pid = fork()) == -1) {              /*创建子进程*/
                printf("Error in fork/n");
                exit(1);
            }

            if(pid == 0) {                          /*执行子进程*/
                printf("in the spawned (child) process.../n");
                close(file_descriptors[INPUT]);     /*子进程向父进程写数据，关闭管道的读端*/
                write(file_descriptors[OUTPUT], "test data", strlen("test data"));
                exit(0);
            } else {
                printf("in the spawning (parent) process.../n");    /*执行父进程*/
                close(file_descriptors[OUTPUT]);                    /*父进程从管道读取子进程写的数据，关闭管道的写端*/
                returned_count = read(file_descriptors[INPUT], buf, sizeof(buf));
                printf("%d bytes of data received from spawned process: %s/n",
                returned_count, buf);
            }
        } 
        a.两个进程通过一个管道只能实现单向通信。比如上面的例子,父进程写子进程读,如果有时候也需要子进程写父进程读,就必须另开一个管道
        b.管道的读写端通过打开的文件描述符来传递,因此要通信的两个进程必须从它们的公共祖先那里继承管道文件描述符。上面的例子是父进程把文件描述符传给子进程之后父子进程之间通信,也可以父进程fork两次,把文件描述符传给两个子进程,然后两个子进程之间通信

        1.如果所有指向管道写端的文件描述符都关闭了(管道写端的引用计数等于0),而仍然有进程从管道的读端读数据,那么管道中剩余的数据都被读取后,再次read会返回0,就像读到文件末尾一样。
        2.如果有指向管道写端的文件描述符没关闭(管道写端的引用计数大于0),而持有管道写端的进程也没有向管道中写数据,这时有进程从管道读端读数据,那么管道中剩余的数据都被读取后,再次read会阻塞,直到管道中有数据可读了才读取数据并返回。
        3.如果所有指向管道读端的文件描述符都关闭了(管道读端的引用计数等于0),这时有进程向管道的写端write,那么该进程会收到信号SIGPIPE,通常会导致进程异常终止.
        4.如果有指向管道读端的文件描述符没关闭(管道读端的引用计数大于0),而持有管道读端的进程也没有从管道中读数据,这时有进程向管道写端写数据,那么在管道被写满时再次write会阻塞,直到管道中有空位置了才写入数据并返回。

======================
    2.有名管道[fifo][first input first output]
        命名管道的系统函数有两个：mknod和mkfifo。两个函数均定义在头⽂文件sys/stat.h
        #include<sys/stat.h>
        #define _PATH_ "/tmp/file.tmp"
        #define _SIZE_ 100

        void write()
        {
            int ret = mkfifo(_PATH_,0666 | S_IFIFO); //创建有名管道/tmp/file.tmp
            int fd = open(_PATH_,O_WRONLY);          //打开
            char buf[_SIZE_];
            memset(buf,'\0',strlen(buf)+1);
            while(1)
            {
                printf("输入命令");
                scanf("%s",buf);
                int ret = write(fd,buf,strlen(buf)+1);//写入数据,最后那个+1存储的是'\0'结束位
            };
        close(fd);
        }
        
        void read()
        {
            int fd = open(_PATH_,O_RDONLY);
            read(fd,buf,_SIZE_);
            printf("%s",buf);
        }
        a.命名管道和管道的使用方法基本是相同的。只是使用命名管道时，必须用open()将其打开。因为命名管道是一个存在于硬盘上的文件，而管道是存在于内存中的特殊文件
        b.需要注意的是，调用open()打开命名管道的进程可能会被阻塞。但如果同时用读写方式（O_RDWR）打开，则一定不会导致阻塞；如果以只读方式（O_RDONLY）打开，则调用open()函数的进程将会被阻塞直到有写方打开管道；同样以写方式（O_WRONLY）打开也会阻塞直到有读方式打开管道。
        c.两个进程通过一个管道只能实现单向通信.如果有时候也需要b进程写a进程读,就必须另开一个管道
        1.试想这样一个问题，只使用一个FIFO文件，如果有多个进程同时向同一个FIFO文件写数据，而只有一个读FIFO进程在同一个FIFO文件中读取数据时，会发生怎么样的情况呢，会发生数据块的相互交错是很正常的？而且个人认为多个不同进程向一个FIFO读进程发送数据是很普通的情况。
        为了解决这一问题，就是让写操作的原子化。怎样才能使写操作原子化呢？答案很简单，系统规定：在一个以O_WRONLY（即阻塞方式）打开的FIFO中， 如果写入的数据长度小于等待PIPE_BUF，那么或者写入全部字节，或者一个字节都不写入。如果所有的写请求都是发往一个阻塞的FIFO的，并且每个写记请求的数据长度小于等于PIPE_BUF字节，系统就可以确保数据决不会交错在一起。

======================
    3.信号[signal]
    一、初步理解信号

    为了理解信号 ,先从我们最熟悉的场景说起:

    1.用户输入命令,在Shell下启动一个前台进程。         

    2.用户按下Ctrl-C,这个键盘输入产生一个硬件中断。         

    3.如果CPU当前正在执行这个进程的代码,则该进程的用户空间代码暂停执行,CPU从用户态切换到内核态处理硬件断。 

    4. 终端驱动程序将Ctrl-C解释成一个SIGINT信号,记在该进程的PCB中(也可以说发送了一个SIGINT信号给该进程)。 

    5. 当某个时刻要从内核返回到该进程的用户空间代码继续执行之前,首先处理PCB中记录的信号,发现有一个SIGINT信号待处理,而这个信号的默认处理动作是终止进程,所以直接终止进程而不再返回它的用户空间代码执行。

    注意,Ctrl-C产生的信号只能发给前台进程。一个命令 后面加个&可以放到后台运行,这样 Shell不必等待进程结束就可以接受新的命令,启动新的进程。Shell可以同时运行一个前台进 程和任意多个后台进程,只有前台进程才能接到Ctrl-C这种控制键产生的信号。前台进程 在运行过程中用户随时可能按下Ctrl-C而产生一个信号,也就是说该进程的用户空间代码执行到任何地方都有可能收到SIGINT信号而终止,所以信号相对于进程的控制流程来说是异步(Asynchronous)的

    二、用kill -l命令可以察看系统定义的信号列表

        #include <unistd.h>    
        #include <sys/types.h>    
        #include <stdlib.h>    
        #include <stdio.h>    
        #include <signal.h>    
            
        static int alarm_fired = 0;    
        
        void ouch(int sig){    
            alarm_fired = 1;    
        }    
        
        int main()    
        {    
            pid_t pid;    
            pid = fork();    
            switch(pid) {    
                case -1:    
                    perror("fork failed\n");    
                    exit(1);    
                case 0:    //子进程    
                    sleep(5);    
                    //向父进程发送信号    
                    kill(getppid(), SIGALRM);    
                exit(0);    
            default:;    
        }    
        //设置处理函数    
            signal(SIGALRM, ouch);    
            while(!alarm_fired) {    
                printf("Hello World!\n");    
                sleep(1);    
            }    
            if(alarm_fired)    
                printf("\nI got a signal %d\n", SIGALRM);    
            exit(0);    
        }    

        在代码中我们使用fork调用复制了一个新进程，在子进程中，5秒后向父进程中发送一个SIGALRM信号，父进程中捕获这个信号，并用ouch函数来处理，变改alarm_fired的值，然后退出循环。
        注：如果父进程在子进程的信号到来之前没有事情可做，我们可以用函数pause（）来挂起父进程，直到父进程接收到信号。当进程接收到一个信号时，预设好的信号处理函数将开始运行，程序也将恢复正常的执行。这样可以节省CPU的资源，因为可以避免使用一个循环来等待。以本例子为例，则可以把while循环改为一句pause();

        signal定义:
            void (*signal(int sig, void (*func)(int)))(int); 
            这是一个相当复杂的声明，耐心点看可以知道signal是一个带有sig和func两个参数的函数，func是一个类型为void (*)(int)的函数指针。该函数返回一个与func相同类型的指针，指向先前指定信号处理函数的函数指针。准备捕获的信号的参数由sig给出，接收到的指定信号后要调用的函数由参数func给出。其实这个函数的使用是相当简单的，通过下面的例子就可以知道。注意信号处理函数的原型必须为void func（int），或者是下面的特殊值：
            SIG_IGN:忽略信号
            SIG_DFL:恢复信号的默认行为
        https://www.cnblogs.com/melons/p/5791795.html
        a.信号量绝对不同于信号，一定要分清
        a.信号量绝对不同于信号，一定要分清

======================
    4.信号量semaphore
        1.概述
        为了防止出现因多个程序同时访问一个共享资源而引发的一系列问题,在任一时刻只能有一个执行线程访问代码的临界区域。临界区域是指执行数据更新的代码需要独占式地执行。信号量的本质是一种数据操作锁，它本身不具有数据交换的功能，而是通过控制其他的通信资源（文件，外部设备）来实现进程间通信。信号量在此过程中负责数据操作的互斥、同步等功能。信号量可以提供这样的一种访问机制，让一个临界区同一时间只有一个线程在访问它，也就是说信号量是用来调协进程对共享资源的访问的。其中共享内存的使用就要用到信号量。
        信号量是一个计数器，通常在内核中实现，用于多个进程对共享数据对象的同步访问。使用信号量的头文件是#include <sys/sem.h>
        2.工作原理
        信号量的使用规则：
            若信号量为正，则进程可使用该资源。
            若信号量为0，则进程阻塞等待，并将进程插入等待队列，直到该信号量的值大于0从等待队列中执行进程请求。
            加锁操作P(sv)：如果信号量大于0，则信号量-1；如果信号量为0，则挂起该进程，并将这个进程插入等待队列。
            解锁操作v(sv)：如果等待队列中有进程则唤醒该进程，让它恢复运行；否则，信号量+1。
        就是两个进程共享信号量sv，一旦其中一个进程执行了P(sv)操作，它将得到信号量，并可以进入临界区，使sv减1。而第二个进程将被阻止进入临界区，因为当它试图执行P(sv)时，sv为0，它会被挂起以等待第一个进程离开临界区域并执行V(sv)释放信号量，这时第二个进程就可以恢复执行。
        3.Linux下使用信号量的常用函数：

            a.int semget (key_t key, int nsem, int oflag)：创建新的信号量或取得已有的信号量，key表示信号量的键值，不相关进程使用同一个key来访问同一个信号量，nsem表示信号量个数（一般为1），oflag表示信号量访问权限，用IPC_CREAT与权限位与可保证信号量不存在时新建一个。函数返回一个int类型的数值，表示信号量的标识符;下面的sem_id。

            b.int semop (int semid, struct sembuf * opsptr, size_t nops)：改变信号量的值，改变操作在opsptr中,是sumbuf结构体对象，使用方法如下： 
            struct sembuf
            {  
                short sem_num;   //除非使用一组信号量，否则它为0  
                short sem_op;    //信号量在一次操作中需要改变的数据，通常是两个数，一个是-1，即P操作（加锁）；一个是+1，即V操作（解锁）
                short sem_flg;   //通常为SEM_UNDO,使操作系统跟踪信号，并在进程没有释放该信号量而终止时，操作系统释放信号量
            };
            参数nops规定opsptr数组中元素个数。
            sem_op值：
            （1）若sem_op为正，这对应于进程释放占用的资源数。sem_op值加到信号量的值上。（V操作）
            （2）若sem_op为负,这表示要获取该信号量控制的资源数。信号量值减去sem_op的绝对值。（P操作）
            （3）若sem_op为0,这表示调用进程希望等待到该信号量值变成0
            如果信号量值小于sem_op的绝对值（资源不能满足要求），则：
            （1）若指定了IPC_NOWAIT，则semop()出错返回EAGAIN。
            （2）若未指定IPC_NOWAIT，则信号量的semncnt值加1（因为调用进程将进 入休眠状态），然后调用进程被挂起直至：①此信号量变成大于或等于sem_op的绝对值；②从系统中删除了此信号量，返回EIDRM；③进程捕捉到一个信 号，并从信号处理程序返回，返回EINTR。（与消息队列的阻塞处理方式 很相似）
            c.int semctl (int semid, int semnum, int cmd, /*可选参数*/ ) :一个信号量执行各种控制操作
                第四个参数是可选的，取决于第三个参数cmd。
                参数semnum指定信号集中的哪个信号（操作对象）
                参数cmd指定以下10种命令中的一种,在semid指定的信号量集合上执行此命令。
                IPC_STAT   读取一个信号量集的数据结构semid_ds，并将其存储在semun中的buf参数中。
                IPC_SET     设置信号量集的数据结构semid_ds中的元素ipc_perm，其值取自semun中的buf参数。
                IPC_RMID  将信号量集从内存中删除。
                GETALL      用于读取信号量集中的所有信号量的值。
                GETNCNT  返回正在等待资源的进程数目。
                GETPID      返回最后一个执行semop操作的进程的PID。
                GETVAL      返回信号量集中的一个单个的信号量的值。
                GETZCNT   返回这在等待完全空闲的资源的进程数目。
                SETALL       设置信号量集中的所有的信号量的值。
                SETVAL      设置信号量集中的一个单独的信号量的值。

        4.信号量的使用实例，同时开两个进程，每个进程中都用信号量同步临界区，在临界区中向屏幕打印字符
            #include <unistd.h>
            #include <sys/types.h>
            #include <sys/stat.h>
            #include <fcntl.h>
            #include <stdlib.h>
            #include <stdio.h>
            #include <string.h>
            #include <sys/sem.h>
         
        union semun
        {
            int val;
            struct semid_ds *buf;
            unsigned short *arry;
        };
 
        static int sem_id = 0;
        static int set_semvalue();
        static void del_semvalue();
        static int semaphore_p();
        static int semaphore_v();
 
        int main(int argc, char *argv[])
        {
            char message = 'X';
            int i = 0;
            sem_id = semget((key_t)1234, 1, 0666 | IPC_CREAT);              //创建信号量
            if(argc > 1)
            {
                if(!set_semvalue())                                         //程序第一次被调用，初始化信号量
                {
                    fprintf(stderr, "Failed to initialize semaphore\n");
                    exit(EXIT_FAILURE);
                }
                message = argv[1][0];                                       //设置要输出到屏幕中的信息，即其参数的第一个字符
                sleep(2);
            }
            for(i = 0; i < 10; ++i)
            {
                if(!semaphore_p())                                          //进入临界区
                exit(EXIT_FAILURE);
                printf("%c", message);                                      //向屏幕中输出数据
                fflush(stdout);                                             //清理缓冲区，然后休眠随机时间
                if(!semaphore_v())                                          //离开临界区，休眠随机时间后继续循环
                exit(EXIT_FAILURE);
                sleep(2);
            }
            sleep(3);
            printf("\n%d - finished\n", getpid());
                                 
            if(argc > 1)
            {                                                               //如果程序是第一次被调用，则在退出前删除信号量
                sleep(3);
                del_semvalue();
            }
            exit(EXIT_SUCCESS);
        }
 
        static int set_semvalue()
        {
        //用于初始化信号量，在sem_union的val字段中设置信号量初值。使用信号量之前必须先初始化！
            union semun sem_union;
            sem_union.val = 1;
            if(semctl(sem_id, 0, SETVAL, sem_union) == -1)
                return 0;
            return 1;
        }
 
        static void del_semvalue()
        {
            //删除信号量
            union semun sem_union;
            if(semctl(sem_id, 0, IPC_RMID, sem_union) == -1)
                printf("Failed to delete semaphore\n");
        }
 
        static int semaphore_p()
        {
            //对信号量做减1操作，即加锁 P（sv）
            struct sembuf sem_b;
            sem_b.sem_num = 0;
            sem_b.sem_op = -1;   //P()
            sem_b.sem_flg = SEM_UNDO;
            if(semop(sem_id, &sem_b, 1) == -1)
            {
                printf("semaphore_p failed\n");
                return 0;
            }
            return 1;
        }
 
        static int semaphore_v()
        {
            //这是一个释放操作，它使信号量变为可用，即解锁 V（sv）
            struct sembuf sem_b;
            sem_b.sem_num = 0;
            sem_b.sem_op = 1;   //V()
            sem_b.sem_flg = SEM_UNDO;
            if(semop(sem_id, &sem_b, 1) == -1)
            {
                printf("semaphore_v failed\n");
                return 0;
            }
            return 1;
        }

======================
    5.共享内存
    共享内存就把一片逻辑内存共享出来，让不同的进程去访问它，修改它.是在多个正在运行的进程之间共享和传递数据的一种非常有效的方式。不同进程之间共享的内存通常安排为同一段物理内存。进程可以将同一段共享内存连接到它们自己的地址空间中，所有进程都可以访问共享内存中的地址，就好像它们是由用C语言函数malloc分配的内存一样。而如果某个进程向共享内存写入数据，所做的改动将立即影响到可以访问同一段共享内存的任何其他进程。

    特别要注意：共享内存并未提供同步机制。也就是说，在第一个进程结束对共享内存的写操作之前，并无自动机制可以阻止第二个进程开始对它进行读取。所以我们通常需要用其他的机制来同步对共享内存的访问，例如信号量。

    a.创建共享内存
    int shmget(key_t key, size_t size, int shmflg);
    第一个参数，共享内存段的命名，shmget函数成功时返回一个与key相关的共享内存标识符（非负整数），用于后续的共享内存函数。调用失败返回-1.
    其它的进程可以通过该函数的返回值访问同一共享内存，它代表进程可能要使用的某个资源，程序对所有共享内存的访问都是间接的，程序先通过调用shmget函数并提供一个键，再由系统生成一个相应的共享内存标识符（shmget函数的返回值），只有shmget函数才直接使用信号量键，所有其他的信号量函数使用由semget函数返回的信号量标识符。
    第二个参数，size以字节为单位指定需要共享的内存容量。
    第三个参数，shmflg是权限标志，它的作用与open函数的mode参数一样，如果要想在key标识的共享内存不存在时，创建它的话，可以与IPC_CREAT做或操作。共享内存的权限标志与文件的读写权限一样，举例来说，0644,它表示允许一个进程创建的共享内存被内存创建者所拥有的进程向共享内存读取和写入数据，同时其他用户创建的进程只能读取共享内存。

    b.启动对该共享内存的访问
    void *shmat(int shm_id, const void *shm_addr, int shmflg);
    第一次创建完共享内存时，它还不能被任何进程访问，shmat函数的作用就是用来启动对该共享内存的访问，并把共享内存连接到当前进程的地址空间。
    第一个参数，shm_id是由shmget函数返回的共享内存标识。
    第二个参数，shm_addr指定共享内存连接到当前进程中的地址位置，通常为空，表示让系统来选择共享内存的地址。
    第三个参数，shm_flg是一组标志位，通常为0。
    调用成功时返回一个指向共享内存第一个字节的指针，如果调用失败返回-1.

    c.将共享内存从当前进程中分离
    int shmdt(const void *shmaddr);
    该函数用于将共享内存从当前进程中分离。注意，将共享内存分离并不是删除它，只是使该共享内存对当前进程不再可用。
    参数shmaddr是shmat函数返回的地址指针，调用成功时返回0，失败时返回-1。

    d.控制共享内存
    int shmctl(int shm_id, int command, struct shmid_ds *buf);
    第一个参数，shm_id是shmget函数返回的共享内存标识符。
    第二个参数，command是要采取的操作，它可以取下面的三个值 ：
            IPC_STAT：把shmid_ds结构中的数据设置为共享内存的当前关联值，即用共享内存的当前关联值覆盖shmid_ds的值。
            IPC_SET：如果进程有足够的权限，就把共享内存的当前关联值设置为shmid_ds结构中给出的值
            IPC_RMID：删除共享内存段
    第三个参数，buf是一个结构指针，它指向共享内存模式和访问权限的结构。
    struct shmid_ds
    {
        uid_t shm_perm.uid;
        uid_t shm_perm.gid;
        mode_t shm_perm.mode;
    ｝


    e.例子共享内存+信号量
    1、server.c
    /*server.c:向共享内存中写入People*/
        #include<stdio.h>
        #include<sys/types.h>
        #include<sys/ipc.h>
        #include<sys/sem.h>
        #include<string.h>
        #include"credis.h"
        int semid;
        int shmid;

        void p()                                        /*信号量的P操作*/
        {
            struct sembuf sem_p;
            sem_p.sem_num=0;/*设置哪个信号量*/
            sem_p.sem_op=-1;/*定义操作*/
            if(semop(semid,&sem_p,1)==-1)
                printf("p operation is fail\n");        /*semop函数自动执行信号量集合上的操作数组。int semop(int semid, struct sembuf semoparray[], size_t nops);semoparray是一个指针，它指向一个信号量操作数组。nops规定该数组中操作的数量。*/
        }

        void v()                                        /*信号量的V操作*/
        {
            struct sembuf sem_v;
            sem_v.sem_num=0;
            sem_v.sem_op=1;
            if(semop(semid,&sem_v,1)==-1)
                printf("v operation is fail\n");
        }

        int main()
        {
            struct  People{
                char name[10];
                int age;
            };
            key_t semkey;
            key_t shmkey;
            semkey=ftok("../test/VenusDB.cbp",0);       //用来产生唯一的标志符，便于区分信号量及共享内存
            shmkey=ftok("../test/main.c",0);
            semid=semget(semkey,1,0666|IPC_CREAT);      //参数nsems,此时为中间值1，指定信号灯集包含信号灯的数目           /*创建信号量的XSI IPC*/   //0666|IPC_CREAT用来表示对信号灯的读写权限
            /*
               从左向右:
               第一位:0表示这是一个8进制数
               第二位:当前用户的经权限:6=110(二进制),每一位分别对就 可读,可写,可执行,6说明当前用户可读可写不可执行
               第三位:group组用户,6的意义同上
               第四位:其它用户,每一位的意义同上,0表示不可读不可写也不可执行
             */
            if(semid==-1)
                printf("creat sem is fail\n");

            shmid=shmget(shmkey,1024,0666|IPC_CREAT);   //创建共享内存
            if(shmid==-1)
                printf("creat shm is fail\n");

            union semun{
                int val;
                struct semid_ds *buf;
                unsignedshort*array;
            }sem_u;

            sem_u.val=1;/*设置变量值*/                  /*设置信号量的初始值，就是资源个数*/

            semctl(semid,0,SETVAL,sem_u);               //初始化信号量，设置第0个信号量，p()操作为非阻塞的

            /*将共享内存映射到当前进程的地址中，之后直接对进程中的地址addr操作就是对共享内存操作*/
            struct  People  *addr;
            addr=(structPeople*)shmat(shmid,0,0);       //将共享内存映射到调用此函数的内存段
            if(addr==(structPeople*)-1)
                printf("shm shmat is fail\n");

            /*向共享内存写入数据*/
            p();
            strcpy((*addr).name,"xiaoming");            /*注意:此处只能给指针指向的地址直接赋值，不能在定义一个 struct People people_1;addr=&people_1;因为addr在addr=(struct People*)shmat(shmid,0,0);时,已经由系统自动分配了一个地址，这个地址与共享内存相关联，所以不能改变这个指针的指向，否则他将不指向共享内存，无法完成通信了。*/
            (*addr).age=10;
            v();

            /*将共享内存与当前进程断开*/
            if(shmdt(addr)==-1)
                printf("shmdt is fail\n");
        }

    2、clinet.c
        /*client.c:从共享内存中读出People*/
            #include<stdio.h>
            #include<sys/types.h>
            #include<sys/ipc.h>
            #include<sys/sem.h>
            int semid;
            int shmid;
            /*信号量的P操作*/
            void p()
            {
                struct sembuf sem_p;
                sem_p.sem_num=0;
                sem_p.sem_op=-1;
                if(semop(semid,&sem_p,1)==-1)
                    printf("p operation is fail\n");
            }
            /*信号量的V操作*/
            void v()
            {
                struct sembuf sem_v;
                sem_v.sem_num=0;
                sem_v.sem_op=1;
                if(semop(semid,&sem_v,1)==-1)
                    printf("v operation is fail\n");
            }
            int main()
            {
                key_t semkey;
                key_t shmkey;
                semkey=ftok("../test/client/VenusDB.cbp",0);
                shmkey=ftok("../test/client/main.c",0);
                structPeople{
                    char name[10];
                    int age;
                };
                /*读取共享内存和信号量的IPC*/
                semid=semget(semkey,0,0666);
                if(semid==-1)
                    printf("creat sem is fail\n");
                shmid=shmget(shmkey,0,0666);
                if(shmid==-1)
                    printf("creat shm is fail\n");

                /*将共享内存映射到当前进程的地址中，之后直接对进程中的地址addr操作就是对共享内存操作*/
                structPeople*addr;
                addr=(structPeople*)shmat(shmid,0,0);
                if(addr==(structPeople*)-1)
                    printf("shm shmat is fail\n");

                /*从共享内存读出数据*/
                p();
                printf("name:%s\n",addr->name);
                printf("age:%d\n",addr->age);
                v();

                /*将共享内存与当前进程断开*/
                if(shmdt(addr)==-1)
                    printf("shmdt is fail\n");
                /*IPC必须显示删除。否则会一直留存在系统中*/
                if(semctl(semid,0,IPC_RMID,0)==-1)
                    printf("semctl delete error\n");
                if(shmctl(shmid,IPC_RMID,NULL)==-1)
                    printf("shmctl delete error\n");
            }

            a.函数ftok把一个已存在的路径名和一个整数标识符转换成一个key_t值，称为IPC键值（也称IPC key键值）
                key_t ftok(const char *pathname, int proj_id)
                pathname：指定的文件，此文件必须存在且可存取
                proj_id：计划代号（project ID）
                1.pathname是目录还是文件的具体路径，是否可以随便设置
                    1、ftok根据路径名，提取文件信息，再根据这些文件信息及project ID合成key，该路径可以随便设置。
                2.pathname指定的目录或文件的权限是否有要求
                    2、该路径是必须存在的，ftok只是根据文件inode在系统内的唯一性来取一个数值，和文件的权限无关。
                3.proj_id是否可以随便设定，有什么限制条件
                    3、proj_id是可以根据自己的约定，随意设置。这个数字,有的称之为project ID; 在UNIX系统上,它的取值是1到255;

            b.在使用ftok()函数时，里面有两个参数，即fname和id，fname为指定的文件名，而id为子序列号，这个函数的返回值就是key，它与指定的文件的索引节点号和子序列号id有关，这样就会给我们一个误解，即只要文件的路径，名称和子序列号不变，那么得到的key值永远就不会变。
                事实上，这种认识是错误的,假如存在这样一种情况：在访问同一共享内存的多个进程先后调用ftok()时间段中，如果fname指向的文件或者目录被删除而且又重新创建，那么文件系统会赋予这个同名文件新的i节点信息，于是这些进程调用的ftok()都能正常返回，但键值key却不一定相同了。
                由此可能造成的后果是，原本这些进程意图访问一个相同的共享内存对象，然而由于它们各自得到的键值不同，实际上进程指向的共享内存不再一致；如果这些共享内存都得到创建，则在整个应用运行的过程中表面上不会报出任何错误，然而通过一个共享内存对象进行数据传输的目 的将无法实现。
                这是一个很重要的问题，希望能谨记！！！
                所以要确保key值不变，要么确保ftok()的文件不被删除，要么不用ftok()，指定一个固定的key值。

======================
    8.UNIX Domain Socket
    　　socket API原本是为网络通讯设计的，但后来在socket的框架上发展出一种IPC机制，就是UNIX Domain Socket。虽然网络socket也可用于同一台主机的进程间通讯（通过loopback地址127.0.0.1），
        但是UNIX Domain Socket用于IPC更有效率：不需要经过网络协议栈，不需要打包拆包、计算校验和、维护序号和应答等，只是将应用层数据从一个进程拷贝到另一个进程。这是因为，IPC机制本质上是可靠的通讯，而网络协议是为不可靠的通讯设计的。
        UNIX Domain Socket也提供面向流和面向数据包两种API接口，类似于TCP和UDP，但是面向消息的UNIX Domain Socket也是可靠的，消息既不会丢失也不会顺序错乱。
    　　UNIX Domain Socket是全双工的，API接口语义丰富，相比其它IPC机制有明显的优越性，目前已成为使用最广泛的IPC机制，比如X Window服务器和GUI程序之间就是通过UNIX Domain Socket通讯的。
        服务端： socket -> bind -> listen -> accet -> recv/send -> close
        客户端： socket -> connect -> recv/send -> close
        进程间通信的一种方式是使用UNIX套接字，人们在使用这种方式时往往用的不是网络套接字，而是一种称为本地套接字的方式。这样做可以避免为黑客留下后门。

        '创建'
        使用套接字函数socket创建，不过传递的参数与网络套接字不同。域参数应该是PF_LOCAL或者PF_UNIX，而不能用PF_INET之类。本地套接字的通讯类型应该是SOCK_STREAM或SOCK_DGRAM，协议为默认协议。例如：
        int sockfd;
        sockfd = socket(PF_LOCAL, SOCK_STREAM, 0);

        '绑定'
        创建了套接字后，还必须进行绑定才能使用。不同于网络套接字的绑定，本地套接字的绑定的是struct sockaddr_un结构。struct sockaddr_un结构有两个参数：sun_family、sun_path。sun_family只能是AF_LOCAL或AF_UNIX，而sun_path是本地文件的路径。通常将文件放在/tmp目录下。例如：
        struct sockaddr_un sun;
        sun.sun_family = AF_LOCAL;
        strcpy(sun.sun_path, filepath);
        bind(sockfd, (struct sockaddr*)&sun, sizeof(sun));

        '监听'
        本地套接字的监听、接受连接操作与网络套接字类似。

        '连接'
        连接到一个正在监听的套接字之前，同样需要填充struct sockaddr_un结构，然后调用connect函数。
        连接建立成功后，我们就可以像使用网络套接字一样进行发送和接受操作了。甚至还可以将连接设置为非阻塞模式

        例子    
        服务器端
            #include <stdio.h>
            #include <sys/stat.h>
            #include <sys/socket.h>
            #include <sys/un.h>
            #include <errno.h>
            #include <stddef.h>
            #include <string.h>

            #define MAX_CONNECTION_NUMBER 5                             // the max connection number of the server

        /* * Create a server endpoint of a connection. * Returns fd if all OK, <0 on error. */
        int unix_socket_listen(const char *servername)
        { 
            int fd;
            struct sockaddr_un un; 
            if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
            {
                return(-1); 
            }
            int len, rval; 
            unlink(servername);               /* in case it already exists */ 
            memset(&un, 0, sizeof(un)); 
            un.sun_family = AF_UNIX; 
            strcpy(un.sun_path, servername); 
            len = offsetof(struct sockaddr_un, sun_path) + strlen(servername); 
            if (bind(fd, (struct sockaddr *)&un, len) < 0)              /* bind the name to the descriptor */ 
            { 
                rval = -2; 
            } 
            else
            {
                if (listen(fd, MAX_CONNECTION_NUMBER) < 0)    
                { 
                    rval =  -3; 
                }
                else
                {
                    return fd;
                }
            }
            int err;
            err = errno;
            close(fd); 
            errno = err;
            return rval;    
        }

        int unix_socket_accept(int listenfd, uid_t *uidptr)
        { 
            int clifd, len, rval; 
            time_t staletime; 
            struct sockaddr_un un;
            struct stat statbuf; 
            len = sizeof(un); 
            if ((clifd = accept(listenfd, (struct sockaddr *)&un, &len)) < 0) 
            {
                return(-1);     
            }
            /* obtain the client's uid from its calling address */ 
            len -= offsetof(struct sockaddr_un, sun_path);  /* len of pathname */
            un.sun_path[len] = 0; /* null terminate */ 
            if (stat(un.sun_path, &statbuf) < 0) 
            {
                rval = -2;
            } 
            else
            {
                if (S_ISSOCK(statbuf.st_mode) ) 
                { 
                    if (uidptr != NULL) *uidptr = statbuf.st_uid;    /* return uid of caller */ 
                    unlink(un.sun_path);       /* we're done with pathname now */ 
                    return clifd;         
                } 
                else
                {
                    rval = -3;     /* not a socket */ 
                }
            }
            int err;
            err = errno; 
            close(clifd); 
            errno = err;
            return(rval);
        }

        void unix_socket_close(int fd)
        {
            close(fd);     
        }

        int main(void)
        { 
            int listenfd,connfd; 
            listenfd = unix_socket_listen("foo.sock");
            if(listenfd<0)
            {
                printf("Error[%d] when listening...\n",errno);
                return 0;
            }
            printf("Finished listening...\n",errno);
            uid_t uid;
            connfd = unix_socket_accept(listenfd, &uid);
            unix_socket_close(listenfd);  
            if(connfd<0)
            {
                printf("Error[%d] when accepting...\n",errno);
                return 0;
            }  
            printf("Begin to recv/send...\n");  
            int i,n,size;
            char rvbuf[2048];
            for(i=0;i<2;i++)
            {
                //===========接收==============
                size = recv(connfd, rvbuf, 804, 0);   
                if(size>=0)
                {
                    // rvbuf[size]='\0';
                    printf("Recieved Data[%d]:%c...%c\n",size,rvbuf[0],rvbuf[size-1]);
                }
                if(size==-1)
                {
                    printf("Error[%d] when recieving Data:%s.\n",errno,strerror(errno));     
                    break;        
                }
                /*
                //===========发送==============
                memset(rvbuf, 'c', 2048);
                size = send(connfd, rvbuf, 2048, 0);
                if(size>=0)
                {
                printf("Data[%d] Sended.\n",size);
                }
                if(size==-1)
                {
                printf("Error[%d] when Sending Data.\n",errno);     
                break;        
                }
                 */
                sleep(30);
            }
            unix_socket_close(connfd);
            printf("Server exited.\n");    
        }

        客户端:
            #include <stdio.h>
            #include <stddef.h>
            #include <sys/stat.h>
            #include <sys/socket.h>
            #include <sys/un.h>
            #include <errno.h>
            #include <string.h>

            /* Create a client endpoint and connect to a server.   Returns fd if all OK, <0 on error. */
            int unix_socket_conn(const char *servername)
            { 
                int fd; 
                if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)    /* create a UNIX domain stream socket */ 
                {
                    return(-1);
                }
                int len, rval;
                struct sockaddr_un un;          
                memset(&un, 0, sizeof(un));            /* fill socket address structure with our address */
                un.sun_family = AF_UNIX; 
                sprintf(un.sun_path, "scktmp%05d", getpid()); 
                len = offsetof(struct sockaddr_un, sun_path) + strlen(un.sun_path);
                unlink(un.sun_path);               /* in case it already exists */ 
                if (bind(fd, (struct sockaddr *)&un, len) < 0)
                { 
                    rval=  -2; 
                } 
                else
                {
                    /* fill socket address structure with server's address */
                    memset(&un, 0, sizeof(un)); 
                    un.sun_family = AF_UNIX; 
                    strcpy(un.sun_path, servername); 
                    len = offsetof(struct sockaddr_un, sun_path) + strlen(servername); 
                    if (connect(fd, (struct sockaddr *)&un, len) < 0) 
                    {
                        rval= -4; 
                    } 
                    else
                    {
                        return (fd);
                    }
                }
                int err;
                err = errno;
                close(fd); 
                errno = err;
                return rval;      
            }

            void unix_socket_close(int fd)
            {
            close(fd);     
            }

            int main(void)
            { 
                srand((int)time(0));
                int connfd; 
                connfd = unix_socket_conn("foo.sock");
                if(connfd<0)
                {
                    printf("Error[%d] when connecting...",errno);
                    return 0;
                }
                printf("Begin to recv/send...\n");  
                int i,n,size;
                char rvbuf[4096];
                for(i=0;i<10;i++)
                {
                    /*
                    //=========接收=====================
                    size = recv(connfd, rvbuf, 800, 0);   //MSG_DONTWAIT
                    if(size>=0)
                    {
                    printf("Recieved Data[%d]:%c...%c\n",size,rvbuf[0],rvbuf[size-1]);
                    }
                    if(size==-1)
                    {
                    printf("Error[%d] when recieving Data.\n",errno);     
                    break;        
                    }
                    if(size < 800) break;
                     */
                    //=========发送======================
                    memset(rvbuf,'a',2048);
                    rvbuf[2047]='b';
                    size = send(connfd, rvbuf, 2048, 0);
                    if(size>=0)
                    {
                        printf("Data[%d] Sended:%c.\n",size,rvbuf[0]);
                    }
                    if(size==-1)
                    {
                        printf("Error[%d] when Sending Data:%s.\n",errno,strerror(errno));     
                        break;        
                    }
                    sleep(1);
                }
                unix_socket_close(connfd);
                printf("Client exited.\n");    
            }

            a.阻塞和非阻塞（SOCK_STREAM方式）
                读写操作有两种操作方式：阻塞和非阻塞。
                1.阻塞模式下
                阻塞模式下，发送数据方和接收数据方的表现情况如同命名管道.
                2.非阻塞模式
                在send或recv函数的标志参数中设置MSG_DONTWAIT，则发送和接收都会返回。如果没有成功，则返回值为-1，errno为EAGAIN 或 EWOULDBLOCK。

            b.socket进程通信命名方式有两种。一是普通的命名，socket会根据此命名创建一个同名的socket文件，客户端连接的时候通过读取该socket文件连接到socket服务端。这种方式的弊端是服务端必须对socket文件的路径具备写权限，客户端必须知道socket文件路径，且必须对该路径有读权限。;另外一种命名方式是抽象命名空间，这种方式不需要创建socket文件，只需要命名一个全局名字，即可让客户端根据此名字进行连接。后者的实现过程与前者的差别是，后者在对地址结构成员sun_path数组赋值的时候，必须把第一个字节置0，即sun_path[0] = 0，下面用代码说明：
            第一种方式：
            //name the server socket 
            server_addr.sun_family = AF_UNIX;
            strcpy(server_addr.sun_path,"/tmp/UNIX.domain");
            server_len = sizeof(struct sockaddr_un);
            client_len = server_len;

            第二种方式：
            #define SERVER_NAME @socket_server
            //name the socket
            server_addr.sun_family = AF_UNIX;
            strcpy(server_addr.sun_path, SERVER_NAME);
            server_addr.sun_path[0]=0;
            //server_len = sizeof(server_addr);
            server_len = strlen(SERVER_NAME)  + offsetof(struct sockaddr_un, sun_path);

            其中，offsetof函数在#include <stddef.h>头文件中定义。因第二种方式的首字节置0，我们可以在命名字符串SERVER_NAME前添加一个占位字符串，例如:#define SERVER_NAME @socket_server  
                前面的@符号就表示占位符，不算为实际名称。
                提示：客户端连接服务器的时候，必须与服务端的命名方式相同，即如果服务端是普通命名方式，客户端的地址也必须是普通命名方式；如果服务端是抽象命名方式，客户端的地址也必须是抽象命名方式。

            c.offsetof :结构体某个成员相对于结构体首地址的偏移量
            struct S2
            {
                int i;
                char c;
            };
            例如，想要获得S2中c的偏移量，方法为:size_t pos = offsetof(S2, c);// pos等于4

5.i2c主从设备交互逻辑-ack
          i2c通信逻辑.主发消息给从read/write 从接收到消息.发ack. 主接收到消息.再发ack给从

6.spi有几种方式 
          https://blog.csdn.net/quartu_flag/article/details/78196221                  需要看图!
          SPI接口的全称是"Serial Peripheral Interface",意为串行外围接口,是Motorola首先在其MC68HCXX系列处理器上定义的。SPI接口主要应用在EEPROM,FLASH,实时时钟,AD转换器,还有数字信号处理器和数字信号解码器之间。
          SPI接口是在CPU和外围低速器件之间进行同步串行数据传输,在主器件的移位脉冲下,数据按位传输,高位在前,地位在后,为全双工通信,数据传输速度总体来说比I2C总线要快,速度最高可达到5Mbps。
          SPI接口是以主从方式工作的,这种模式通常有一个主器件和一个或多个从器件,其接口包括以下四种信号：
          （1）MOSI– 主器件数据输出,从器件数据输入
          （2）MISO– 主器件数据输入,从器件数据输出
          （3）SCLK– 时钟信号,由主器件产生
          （4）/SS  – 从器件使能信号,由主器件控制

          spi四种模式SPI的相位(CPHA)和极性(CPOL)分别可以为0或1，对应的4种组合构成了SPI的4种模式(mode)

          Mode 0 CPOL=0, CPHA=0 
          Mode 1 CPOL=0, CPHA=1
          Mode 2 CPOL=1, CPHA=0 
          Mode 3 CPOL=1, CPHA=1

          时钟极性CPOL: 即SPI空闲时，时钟信号SCLK的电平（1:空闲时高电平; 0:空闲时低电平）
          时钟相位CPHA: 即SPI在SCLK第几个边沿开始采样（0:第一个边沿开始; 1:第二个边沿开始）
          sd卡的spi常用的是mode 0 和mode 3，这两种模式的相同的地方是都在时钟上升沿采样传输数据，区别这两种方式的简单方法就是看空闲时，时钟的电平状态，低电平为mode 0 ，高电平为mode 3。

          最后,SPI接口的一个缺点：没有指定的流控制,没有应答机制确认是否接收到数据。ack机制,i2c有的.


7.写一个完整的回调函数
          如果参数是一个函数指针，调用者可以传递一个函数的地址给实现者，让实现者去调用它，这称为回调函数（Callback Function）
          int (*func)(void);函数指针，指向的函数为空参数，返回整型；
          void function(int(*func)(void),int tmp);包含函数指针.是回调函数

          例子:
            void caller(void(*ptr)())
            {
                ptr(); /* 调用ptr指向的函数 */ 
            }

            void func()
            {
                printk("hello_world\n");
            }

            int main()
            {
                void (*p) (); //p是指向某函数的指针
                p = func; 
                caller(p); /* 传递函数地址到调用者 */
            }

