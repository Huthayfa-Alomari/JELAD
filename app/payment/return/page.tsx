import Link from "next/link";

export default async function PaymentReturnPage({
  searchParams,
}: {
  searchParams: Promise<{ jobId?: string }>;
}) {
  const params = await searchParams;
  return (
    <main className="min-h-screen bg-[#f7f7f5] px-5 py-16">
      <div className="mx-auto max-w-lg rounded-3xl bg-white p-8 text-center ring-1 ring-black/5">
        <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-[#eef2f6] text-xl">✓</div>
        <h1 className="mt-5 text-2xl font-semibold">عدت من بوابة الدفع</h1>
        <p className="mt-3 text-sm leading-6 text-[#667085]">
          تم استلامك من PayTabs. حالة الدفع النهائية يتم تثبيتها من الخادم عبر callback الآمن.
          افتح تطبيق JELAD واضغط «تحقق من الدفع» للانتقال إلى التتبع بعد التأكيد.
        </p>
        {params.jobId ? (
          <p className="mt-5 text-xs text-[#98a2b3]">رقم الطلب: {params.jobId}</p>
        ) : null}
        <Link href="/" className="mt-7 inline-flex rounded-2xl bg-[#182230] px-5 py-3 text-sm font-semibold text-white">
          العودة إلى JELAD
        </Link>
      </div>
    </main>
  );
}
