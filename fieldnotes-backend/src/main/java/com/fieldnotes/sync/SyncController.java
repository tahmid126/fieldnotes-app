package com.fieldnotes.sync;

import com.fieldnotes.common.dto.ApiResponse;
import com.fieldnotes.security.SecurityUtils;
import com.fieldnotes.sync.dto.SyncRequest;
import com.fieldnotes.sync.dto.SyncResponse;
import com.fieldnotes.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    @PostMapping
    public ResponseEntity<ApiResponse<SyncResponse>> syncData(@RequestBody SyncRequest request) {
        User user = SecurityUtils.getCurrentUser();
        SyncResponse response = syncService.syncData(request, user);
        return ResponseEntity.ok(ApiResponse.success("Sync completed successfully", response));
    }

    @GetMapping("/restore")
    public ResponseEntity<ApiResponse<SyncResponse>> getAllDataForRestore() {
        User user = SecurityUtils.getCurrentUser();
        SyncResponse response = syncService.getAllDataForRestore(user);
        return ResponseEntity.ok(ApiResponse.success("Data restored successfully", response));
    }
}
