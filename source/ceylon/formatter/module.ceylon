"A formatter for the Ceylon programming language."
by ("Lucas Werkmeister <mail@lucaswerkmeister.de>")
license("http://www.apache.org/licenses/LICENSE-2.0.html")
module ceylon.formatter "1.1.0" {
    shared import java.base "7";
    shared import com.redhat.ceylon.typechecker "1.1.0";
    shared import com.redhat.ceylon.common "1.1.0";
    shared import ceylon.file "1.1.0";
    import ceylon.time "1.1.0";
    import ceylon.interop.java "1.1.0";
    import ceylon.collection "1.1.0";
    optional import ceylon.test "1.1.0"; // for tests only, remove for release!
}
