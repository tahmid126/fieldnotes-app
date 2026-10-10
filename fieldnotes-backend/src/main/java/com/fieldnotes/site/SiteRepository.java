package com.fieldnotes.site;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SiteRepository extends JpaRepository<Site, UUID> {

    List<Site> findAllByUserIdAndDeletedFalseOrderByNameAsc(UUID userId);

    List<Site> findAllByCustomerIdAndUserIdAndDeletedFalseOrderByNameAsc(UUID customerId, UUID userId);

    Optional<Site> findByIdAndUserId(UUID id, UUID userId);

    Optional<Site> findByIdAndUserIdAndDeletedFalse(UUID id, UUID userId);

    List<Site> findByUserIdAndUpdatedAtAfter(UUID userId, LocalDateTime updatedAt);

    List<Site> findAllByUserId(UUID userId);
}
