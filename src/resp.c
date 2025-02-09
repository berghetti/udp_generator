
#include <stdio.h>
#include <string.h>

/* encode array of bulk strings
 * return lenght of buffer or -1 if error
 * https://redis.io/docs/latest/develop/reference/protocol-spec/#arrays*/
int
resp_encode (char *buff, unsigned buff_size, char **cmd, unsigned cmd_count)
{
  char *p = buff;
  int ret = snprintf (p, buff_size, "*%d\r\n", cmd_count);

  /* buff truncated */
  if (ret >= (int)buff_size)
    return -1;

  p += ret;
  buff_size -= ret;

  for (unsigned i = 0; i < cmd_count; i++)
    {
      ret = snprintf (p, buff_size, "$%ld\r\n%s\r\n", strlen (cmd[i]), cmd[i]);

      /* buff truncated */
      if (ret >= (int)buff_size)
        return -1;

      p += ret;
      buff_size -= ret;
    }

  return p - buff;
}
