shared native void run();
shared native ("jvm") void run() {
    import java.lang {
        System
    }
    System.\iout.println("Hello, World!");
}
shared native ("js") void run() {
    dynamic { console.log("Hello, World!"); }
}
