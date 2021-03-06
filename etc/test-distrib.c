#include <stdio.h>

char string[] = "Testing distribution of nonprinting chars:\n\
Should be 0177: \177 Should be 0377: \377 Should be 0212: \212.\n\
Should be 0000: \0.\n\
This file is read by the `test-distribution' program.\n\
If you change it, you will make that program fail.\n";

main ()
{
  int fd = open ("testfile", 0);
  char buf[300];
  int nread;

  if (fd < 0)
    {
      perror ("opening `testfile'");
      exit (1);
    }
  bzero (buf, sizeof buf);
  nread = read (fd, buf, sizeof string);
  if (nread != sizeof string - 1 || strcmp (buf, string))
    {
      fprintf (stderr, "Data in file `testfile' has been damaged.\n\
Most likely this means that many nonprinting characters\n\
have been corrupted in the files of Emacs, and it will not work.\n");
      exit (1);
    }
  close (fd);
  exit (0);
}
