package dev.plom.plomgit;

import dev.plom.plomgit.R;

import android.database.Cursor;
import android.database.MatrixCursor;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsContract.Document;
import android.provider.DocumentsContract.Root;
import android.provider.DocumentsProvider;
import android.util.Log;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

public class PlomGitRepositoryProvider extends DocumentsProvider
{
    private static final String TAG = "PlomGitRepoProvider";

    @Override public boolean onCreate ()
    {
        return true;
    }

    private static final String[] DEFAULT_DOCUMENT_PROJECTION = new String[] {
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_MIME_TYPE,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_LAST_MODIFIED,
            Document.COLUMN_FLAGS,
            Document.COLUMN_SIZE
    };

    private File getRepoDir()
    {
        return new File(getContext().getExternalFilesDir(null), "/repositories");
    }

    private void addFileToCursor(MatrixCursor cursor, String documentId) {
        File file = new File(getRepoDir(), documentId.substring(1));

        MatrixCursor.RowBuilder row = cursor.newRow();
        row.add(Document.COLUMN_DOCUMENT_ID, documentId);
        // Sometimes, we haven't initialized the repository directory yet but still need to
        // show the roots, so we check if file is a directory or if we're looking for the root
        // directory (which may not exist yet)
        if (file.isDirectory() || documentId.equals("/")) {
            row.add(Document.COLUMN_MIME_TYPE, Document.MIME_TYPE_DIR);
            if (documentId.equals("/"))
                row.add(Document.COLUMN_FLAGS, 0);
            else
                row.add(Document.COLUMN_FLAGS, Document.FLAG_DIR_SUPPORTS_CREATE
                        | Document.FLAG_SUPPORTS_DELETE | Document.FLAG_SUPPORTS_REMOVE
                        | Root.FLAG_SUPPORTS_IS_CHILD);
            row.add(Document.COLUMN_SIZE, 0);
        } else  {
            String mimeType = "application/octet-stream";
            row.add(Document.COLUMN_MIME_TYPE, mimeType);
            row.add(Document.COLUMN_FLAGS, Document.FLAG_SUPPORTS_DELETE
                    | Document.FLAG_SUPPORTS_WRITE | Document.FLAG_SUPPORTS_REMOVE
                    | Root.FLAG_SUPPORTS_IS_CHILD);
            row.add(Document.COLUMN_SIZE, file.length());
        }
        row.add(Document.COLUMN_DISPLAY_NAME, file.getName());
        row.add(Document.COLUMN_LAST_MODIFIED, file.lastModified());
    }

    @Override
    public Cursor queryRoots (String[] projection)
    {
        Log.v(TAG, "queryRoots");

        if (projection == null || projection.length == 0) {
            projection = new String[] {
                Root.COLUMN_ROOT_ID,
                Root.COLUMN_MIME_TYPES,
                Root.COLUMN_FLAGS,
                Root.COLUMN_ICON,
                Root.COLUMN_TITLE,
                Root.COLUMN_SUMMARY,
                Root.COLUMN_DOCUMENT_ID,
                Root.COLUMN_AVAILABLE_BYTES,
            };
        }

        MatrixCursor cursor = new MatrixCursor(projection);
        MatrixCursor.RowBuilder row = cursor.newRow();
        row.add(Root.COLUMN_ROOT_ID, PlomGitRepositoryProvider.class.getName() + ".gitrepos");
        row.add(Root.COLUMN_FLAGS, Root.FLAG_SUPPORTS_CREATE | Root.FLAG_SUPPORTS_IS_CHILD);
        row.add(Root.COLUMN_TITLE, "PlomGit");
        row.add(Root.COLUMN_SUMMARY, "git repositories");
        row.add(Root.COLUMN_DOCUMENT_ID, "/");
        row.add(Root.COLUMN_MIME_TYPES, "*/*");
        row.add(Root.COLUMN_AVAILABLE_BYTES, Integer.MAX_VALUE);
        row.add(Root.COLUMN_ICON, R.drawable.ic_storageprovider_root);

        return cursor;
    }

    @Override
    public Cursor queryChildDocuments (String parentDocumentId, String[] projection, String sortOrder)
            throws FileNotFoundException
    {
        Log.v(TAG, "queryChildDocuments " + parentDocumentId);

        if (projection == null || projection.length == 0)
            projection = DEFAULT_DOCUMENT_PROJECTION;
        final MatrixCursor result = new MatrixCursor(projection);

        if (!parentDocumentId.startsWith("/"))
            throw new FileNotFoundException();
        File [] dirListing;
        if (parentDocumentId.equals("/")) {
            // The root is just a list of repositories
            dirListing = getRepoDir().listFiles();
        }
        else
        {
            dirListing = new File(getRepoDir(), parentDocumentId.substring(1)).listFiles();
        }
        if (dirListing != null)
        {
            for (File file : dirListing)
            {
                addFileToCursor(result, parentDocumentId + "/" + file.getName());
            }
        }
        return result;
    }

    @Override
    public Cursor queryDocument (String documentId, String[] projection)
            throws FileNotFoundException
    {
        Log.v(TAG, "queryDocument" + documentId);

        if (projection == null || projection.length == 0)
            projection = DEFAULT_DOCUMENT_PROJECTION;
        final MatrixCursor result = new MatrixCursor(projection);

        if (!documentId.startsWith("/"))
            throw new FileNotFoundException();
        addFileToCursor(result, documentId);
        return result;
    }

    @Override
    public ParcelFileDescriptor openDocument (String documentId, String mode, CancellationSignal signal) throws FileNotFoundException
    {
        Log.v(TAG, "openDocument " + documentId);
        File file = new File(getRepoDir(), documentId.substring(1));
        final int accessMode = ParcelFileDescriptor.parseMode(mode);
        return ParcelFileDescriptor.open(file, accessMode);
    }

    @Override
    public String createDocument(String parentDocumentId, String mimeType, String displayName) throws FileNotFoundException
    {
        Log.v(TAG, "createDocument " + displayName + " in " + parentDocumentId + " mime: " + mimeType);
        File file = new File(new File(getRepoDir(), parentDocumentId.substring(1)), displayName);
        try {
            if (Document.MIME_TYPE_DIR.equals(mimeType))
            {
                if (file.mkdir())
                    return parentDocumentId + "/" + displayName;
                else
                    throw new FileNotFoundException();
            }
            else
            {
                file.createNewFile();
                return parentDocumentId + "/" + displayName;

            }
        }
        catch (IOException e)
        {
            throw new FileNotFoundException();
        }
    }

    @Override
    public boolean isChildDocument(String parentDocumentId, String documentId)
    {
        String [] parentPaths = parentDocumentId.split("/");
        String [] childPaths = documentId.split("/");
        if (parentPaths.length > childPaths.length) return false;
        for (int n = 0; n < childPaths.length; n++)
        {
            if (!childPaths[n].equals(parentPaths[n]))
                return false;
        }
        return true;
    }

    @Override
    public void removeDocument(String documentId, String parentDocumentId) throws FileNotFoundException {
        if (!new File(getRepoDir(), documentId.substring(1)).delete())
            throw new FileNotFoundException();
    }

    @Override
    public void deleteDocument(String documentId) throws FileNotFoundException {
        if (!new File(getRepoDir(), documentId.substring(1)).delete())
            throw new FileNotFoundException();
    }
}