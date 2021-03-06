/* movemail foo bar -- move file foo to file bar,
   locking file foo the way /bin/mail respects.
   Copyright (C) 1985 Richard M. Stallman.

This file is part of GNU Emacs.

GNU Emacs is distributed in the hope that it will be useful,
but without any warranty.  No author or distributor
accepts responsibility to anyone for the consequences of using it
or for whether it serves any particular purpose or works at all,
unless he says so in writing.

Everyone is granted permission to copy, modify and redistribute
GNU Emacs, but only under the conditions described in the
document "GNU Emacs copying permission notice".   An exact copy
of the document is supposed to have been given to you along with
GNU Emacs so that you can know how you may redistribute it all.
It should be in a file named COPYING.  Among other things, the
copyright notice and this notice must be preserved on all copies.  */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>

char *concat ();

main (argc, argv)
     int argc;
     char **argv;
{
  char *inname, *outname;
  int indesc, outdesc;
  long now;
  int tem;
  char *lockname, *p;
  char tempname[40];
  int desc;
  char buf[1024];
  int nread;
  struct stat st;

  if (argc < 3)
    fatal ("two arguments required");

  inname = argv[1];
  outname = argv[2];

  lockname = concat (inname, ".lock", "");
  strcpy (tempname, inname);
  p = tempname + strlen (tempname);
  while (p != tempname && p[-1] != '/')
    p--;
  *p = 0;
  strcpy (p, "EXXXXXX");
  mktemp (tempname);
  unlink (tempname);

  while (1)
    {
      desc = open (tempname, O_WRONLY | O_CREAT, 0666);
      close (desc);
      tem = link (tempname, lockname);
      unlink (tempname);
      if (tem >= 0)
	break;
      sleep (1);

      /* If lock file is a minute old, unlock it.  */
      if (stat (lockname, &st) >= 0)
	{
	  now = time (0);
	  if (st.st_ctime < now - 60)
	    unlink (lockname);
	}
    }

  indesc = open (inname, O_RDONLY);
  if (indesc < 0)
    pfatal_with_name (inname);
  outdesc = open (outname, O_WRONLY | O_CREAT | O_EXCL, 0777);
  if (outdesc < 0)
    pfatal_with_name (outname);

  while (1)
    {
      nread = read (indesc, buf, sizeof buf);
      if (nread != write (outdesc, buf, nread))
	fatal ("error writing to %s", outname);
      if (nread < sizeof buf)
	break;
    }

  close (indesc);
  close (outdesc);
  unlink (inname);
  unlink (lockname);
  exit (0);
}

/* Print error message and exit.  */

fatal (s1, s2)
     char *s1, *s2;
{
  error (s1, s2);
  exit (1);
}

/* Print error message.  `s1' is printf control string, `s2' is arg for it. */

error (s1, s2)
     char *s1, *s2;
{
  printf ("movemail: ");
  printf (s1, s2);
  printf ("\n");
}

pfatal_with_name (name)
     char *name;
{
  extern int errno, sys_nerr;
  extern char *sys_errlist[];
  char *s;

  if (errno < sys_nerr)
    s = concat ("", sys_errlist[errno], " for %s");
  else
    s = "cannot open %s";
  fatal (s, name);
}

/* Return a newly-allocated string whose contents concatenate those of s1, s2, s3.  */

char *
concat (s1, s2, s3)
     char *s1, *s2, *s3;
{
  int len1 = strlen (s1), len2 = strlen (s2), len3 = strlen (s3);
  char *result = (char *) xmalloc (len1 + len2 + len3 + 1);

  strcpy (result, s1);
  strcpy (result + len1, s2);
  strcpy (result + len1 + len2, s3);
  *(result + len1 + len2 + len3) = 0;

  return result;
}

/* Like malloc but get fatal error if memory is exhausted.  */

int
xmalloc (size)
     int size;
{
  int result = malloc (size);
  if (!result)
    fatal ("virtual memory exhausted", 0);
  return result;
}
